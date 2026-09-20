import Foundation
import SwiftData
@MainActor final class GameController: ObservableObject {
 @Published var currentHits=0; @Published var active=false
 var silenceSeconds:TimeInterval=3; var minimumHits=2
 private var start:Date?,lastHit:Date?,timer:Timer?;var session:SessionRecord?
 func startSession(context:ModelContext){let s=SessionRecord();context.insert(s);session=s;currentHits=0;active=true;timer=Timer.scheduledTimer(withTimeInterval:0.25,repeats:true){[weak self]_ in Task{@MainActor in self?.tick(context)}}}
 func hit(context:ModelContext){guard active else{return};if currentHits==0{start = .now};currentHits += 1;lastHit = .now}
 private func tick(_ context:ModelContext){guard currentHits>0,let h=lastHit,Date().timeIntervalSince(h)>=silenceSeconds else{return};finishRally(context)}
 func finishRally(_ context:ModelContext){guard currentHits>0 else{return};if currentHits>=minimumHits,let s=start{let r=RallyRecord(startedAt:s,endedAt:lastHit ?? .now,hits:currentHits);r.session=session;context.insert(r)};currentHits=0;start=nil;lastHit=nil;try? context.save()}
 func stop(context:ModelContext){finishRally(context);session?.endedAt = .now;active=false;timer?.invalidate();timer=nil;try? context.save()}
}
