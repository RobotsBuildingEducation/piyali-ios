import SwiftUI

struct CommunityFeedView:View {
    @EnvironmentObject var app:AppModel
    @StateObject private var service=CommunityFeedService()
    @State private var preview=false
    @State private var posting=false
    @State private var published=false
    @State private var shareState:LearnerState?
    @State private var shareAuthor=""
    var body:some View {
        List {
            Section {
                Text("#LearnWithNostr").font(.headline)
                Text("Learning milestones shared publicly on Nostr.")
                Button("Share my progress") { shareState=app.learner;shareAuthor=app.identity.hex;preview=true }.disabled(posting).accessibilityIdentifier("communityShare")
                if published { Text("Progress published.").accessibilityIdentifier("communityPublished") }
            }
            if service.busy { ProgressView("Syncing with the community…") }
            if let error=service.error { Text(error).foregroundStyle(.red) }
            if service.posts.isEmpty,!service.busy { Text("No learning posts yet. Pull to refresh.") }
            ForEach(service.posts) { post in
                Section {
                    Link(post.name,destination:URL(string:"https://ditto.pub/"+post.npub)!)
                    Text(Date(timeIntervalSince1970:Double(post.event.created_at)),style:.date).font(.caption)
                    if let percent=post.milestone.questionPercent { ProgressView(value:percent,total:100);Text("Question \(post.milestone.question!.formatted()) of 120") }
                    if let xp=post.milestone.totalXP { Text("Total XP: \(xp.formatted())") }
                    if let percent=post.milestone.goalPercent { ProgressView(value:percent,total:100);Text("Goal completion: \(percent.formatted())%") }
                    Text(linked(post.event.content)).textSelection(.enabled)
                }
            }
        }.navigationTitle("Community feed")
        .toolbar { Button("Refresh") { Task { await service.refresh(account:app.identity.npub,force:true) } }.disabled(service.busy || posting) }
        .refreshable { await service.refresh(account:app.identity.npub,force:true) }
        .task(id:app.identity.npub) { await service.refresh(account:app.identity.npub) }
        .onDisappear { service.cancel() }
        .onChange(of:app.identity.npub) { _,_ in preview=false;shareState=nil;published=false }
        .sheet(isPresented:$preview) {
            NavigationStack {
                Form {
                    Text("This post and your Nostr identity will be public. Copies may remain on relays.")
                    Text(CommunityMilestone.progress(shareState ?? app.learner).content).textSelection(.enabled)
                    Button("Publish publicly") {
                        let state=shareState ?? app.learner,author=shareAuthor;preview=false;posting=true;published=false
                        Task { defer { posting=false };do { try await service.publish(state,identity:app.identity,expectedAuthor:author);if app.identity.hex == author { published=true } } catch { if app.identity.hex == author,!(error is CancellationError) { service.error=error.localizedDescription } } }
                    }.accessibilityIdentifier("communityConfirm")
                }.navigationTitle("Share progress").toolbar { Button("Cancel") { preview=false } }
            }
        }
    }
    private func linked(_ text:String) -> AttributedString {
        var result=AttributedString(text)
        if let detector=try? NSDataDetector(types:NSTextCheckingResult.CheckingType.link.rawValue) {
            for match in detector.matches(in:text,range:NSRange(text.startIndex...,in:text)) {
                guard let url=match.url,["https","http"].contains(url.scheme?.lowercased() ?? ""),let source=Range(match.range,in:text),let range=Range(source,in:result) else { continue };result[range].link=url
            }
        };return result
    }
}
