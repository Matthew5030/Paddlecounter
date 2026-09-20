import Foundation
struct AudioFeatures { let centroid: Float; let highRatio: Float; let peakToRMS: Float; let rms: Float }
struct SoundProfile: Codable { var centroid: Float; var highRatio: Float; var peakToRMS: Float; var rms: Float; var count: Int }
final class CalibrationStore {
 static let shared = CalibrationStore(); private let key="paddleSoundProfile"
 var profile: SoundProfile? {
  get { guard let d=UserDefaults.standard.data(forKey:key) else{return nil}; return try? JSONDecoder().decode(SoundProfile.self,from:d) }
  set { if let v=newValue,let d=try? JSONEncoder().encode(v){UserDefaults.standard.set(d,forKey:key)}else{UserDefaults.standard.removeObject(forKey:key)} }
 }
 func add(_ f: AudioFeatures) {
  let n=Float(profile?.count ?? 0), p=profile ?? SoundProfile(centroid:0,highRatio:0,peakToRMS:0,rms:0,count:0)
  profile=SoundProfile(centroid:(p.centroid*n+f.centroid)/(n+1),highRatio:(p.highRatio*n+f.highRatio)/(n+1),peakToRMS:(p.peakToRMS*n+f.peakToRMS)/(n+1),rms:(p.rms*n+f.rms)/(n+1),count:p.count+1)
 }
 func reset(){profile=nil}
}
