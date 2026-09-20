import AVFoundation
import Accelerate
import Foundation
@MainActor final class AudioDetector: ObservableObject {
 @Published var isRunning=false;@Published var lastConfidence:Float=0;@Published var calibrationHits=CalibrationStore.shared.profile?.count ?? 0
 var onHit:((Float)->Void)?;var calibrationMode=false;var threshold:Float=0.70
 private let engine=AVAudioEngine();private var lastEvent=Date.distantPast
 func start() async throws {
  let ok=await AVAudioApplication.requestRecordPermission();guard ok else{throw NSError(domain:"PaddleCounter",code:1,userInfo:[NSLocalizedDescriptionKey:"Microphone permission is required."])}
  let session=AVAudioSession.sharedInstance();try session.setCategory(.record,mode:.measurement);try session.setActive(true)
  let input=engine.inputNode,format=input.outputFormat(forBus:0);input.removeTap(onBus:0)
  input.installTap(onBus:0,bufferSize:2048,format:format){[weak self] b,_ in guard let f=Self.features(b,Float(format.sampleRate)) else{return};Task{@MainActor in self?.consume(f)}}
  engine.prepare();try engine.start();isRunning=true
 }
 func stop(){engine.inputNode.removeTap(onBus:0);engine.stop();try? AVAudioSession.sharedInstance().setActive(false);isRunning=false}
 private func consume(_ f:AudioFeatures){
  guard f.rms>0.012,f.peakToRMS>2.2,Date().timeIntervalSince(lastEvent)>0.12 else{return};lastEvent = .now
  if calibrationMode{CalibrationStore.shared.add(f);calibrationHits=CalibrationStore.shared.profile?.count ?? 0;lastConfidence=1;return}
  guard let p=CalibrationStore.shared.profile,p.count>=5 else{return}
  let d1=abs(f.centroid-p.centroid)/max(p.centroid,300),d2=abs(f.highRatio-p.highRatio)/max(p.highRatio,0.08),d3=abs(f.peakToRMS-p.peakToRMS)/max(p.peakToRMS,1),d4=abs(f.rms-p.rms)/max(p.rms,0.02)
  let c=max(0,min(1,1-(0.4*d1+0.3*d2+0.2*d3+0.1*d4)));lastConfidence=c;if c>=threshold{onHit?(c)}
 }
 nonisolated static func features(_ b:AVAudioPCMBuffer,_ rate:Float)->AudioFeatures?{
  guard let ch=b.floatChannelData?[0] else{return nil};let n=Int(b.frameLength);guard n>=256 else{return nil}
  var rms:Float=0,peak:Float=0;vDSP_rmsqv(ch,1,&rms,vDSP_Length(n));vDSP_maxmgv(ch,1,&peak,vDSP_Length(n))
  let count=1024;var samples=[Float](repeating:0,count:count);for i in 0..<min(n,count){samples[i]=ch[i]}
  var window=[Float](repeating:0,count:count);vDSP_hann_window(&window,vDSP_Length(count),Int32(vDSP_HANN_NORM));vDSP_vmul(samples,1,window,1,&samples,1,vDSP_Length(count))
  let log2n=vDSP_Length(10);guard let setup=vDSP_create_fftsetup(log2n,FFTRadix(kFFTRadix2)) else{return nil};defer{vDSP_destroy_fftsetup(setup)}
  var real=[Float](repeating:0,count:count/2),imag=[Float](repeating:0,count:count/2)
  samples.withUnsafeBufferPointer{$0.baseAddress!.withMemoryRebound(to:DSPComplex.self,capacity:count/2){cp in real.withUnsafeMutableBufferPointer{rp in imag.withUnsafeMutableBufferPointer{ip in var s=DSPSplitComplex(realp:rp.baseAddress!,imagp:ip.baseAddress!);vDSP_ctoz(cp,2,&s,1,vDSP_Length(count/2));vDSP_fft_zrip(setup,&s,1,log2n,FFTDirection(FFT_FORWARD))}}}}
  var mags=[Float](repeating:0,count:count/2);real.withUnsafeMutableBufferPointer{rp in imag.withUnsafeMutableBufferPointer{ip in var s=DSPSplitComplex(realp:rp.baseAddress!,imagp:ip.baseAddress!);vDSP_zvabs(&s,1,&mags,1,vDSP_Length(count/2))}}
  var sum:Float=0,weighted:Float=0,high:Float=0;for i in 1..<mags.count{let hz=Float(i)*rate/Float(count);sum += mags[i];weighted += mags[i]*hz;if hz>2500{high += mags[i]}}
  return AudioFeatures(centroid:weighted/max(sum,0.001),highRatio:high/max(sum,0.001),peakToRMS:peak/max(rms,0.0001),rms:rms)
 }
}
