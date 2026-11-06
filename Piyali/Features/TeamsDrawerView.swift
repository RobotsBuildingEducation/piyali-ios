import SwiftUI

/// The root product's shared team drawer. Public rosters and legacy invitations share one list.
struct TeamsDrawerView:View {
    @EnvironmentObject var app:AppModel
    @Environment(\.colorScheme) private var scheme
    @StateObject private var model:TeamsPanelController
    let onClose:()->Void
    @State private var tab=0
    @State private var mounted=false
    @State private var expanded:Set<String>=[]
    @State private var editor:TeamsEditor?
    @State private var removal:JSONValue?
    @State private var confirmationOwner=UUID()
    @State private var name=""
    @State private var member=""
    @State private var queued:[String]=[]
    @FocusState private var field:String?
    private var light:Bool{scheme != .dark}
    private var brand:PiyaliBrand{.init(dark:!light)}
    private var language:String{app.learner.support}
    private var rtl:Bool{language == "ar"}
    private func directed(_ value:String)->String{rtl ? "\u{200F}"+value+"\u{200F}":value}
    private func text(_ value:String)->some View{Text(directed(value)).accessibilityLabel(value)}
    private var pending:[JSONValue]{model.snapshot.invites.filter{$0["status"].string == "pending"}}
    private func c(_ value:String)->Color{PiyaliBrand.unitColor(value)}
    private var ink:Color{light ? brand.text:c("e5e7eb")}
    private var muted:Color{light ? c("5b4b3a"):c("a3b4c9")}
    private var surface:Color{light ? c("fdf9f2"):c("0b1220")}
    private var border:Color{light ? brand.border:.white.opacity(0.2)}
    private var cardBorder:Color{light ? border:.white.opacity(0.08)}
    private func t(_ key:String,_ fallback:String)->String{let value=EntryCopy.ui(language,key);return value.isEmpty || value == key ? fallback:value}
    init(service:NostrTeamsService,initial:TeamsPanelSnapshot?=nil,initialOwner:String="",onClose:@escaping()->Void){_model=StateObject(wrappedValue:TeamsPanelController(access:LiveTeamsPanelAccess(service:service),initial:initial ?? .init(),initialOwner:initial == nil ? "":initialOwner));self.onClose=onClose}
    init(model:TeamsPanelController,initialTab:Int=0,initialEditor:TeamsEditor?=nil,initialMembers:[String]=[],initialMember:String="",onClose:@escaping()->Void){_model=StateObject(wrappedValue:model);_tab=State(initialValue:initialTab);_editor=State(initialValue:initialEditor);_name=State(initialValue:initialEditor?.team?["teamName"].string ?? "");_queued=State(initialValue:initialMembers);_member=State(initialValue:initialMember);self.onClose=onClose}
    var body:some View {
        GeometryReader{g in
            ZStack(alignment:.bottom){
                Color.clear.contentShape(Rectangle()).onTapGesture(perform:onClose)
                VStack(spacing:0){
                    Capsule().fill(ink.opacity(0.24)).frame(width:52,height:5).padding(.top,12).padding(.bottom,8)
                    text(t("teams_drawer_title","Teams")).font(.system(size:20,weight:.semibold)).frame(height:30).frame(maxWidth:.infinity,alignment:.leading).padding(.horizontal,32).padding(.vertical,28)
                    ScrollView{VStack(spacing:0){
                        HStack(spacing:16){tabButton(0,t("teams_tab_view","Teams")+(pending.isEmpty ? "":" (\(pending.count))"));tabButton(1,t("teams_tab_feed","Global feed"))}.padding(.bottom,8)
                        VStack(alignment:.leading,spacing:16){if tab == 0{teamList}else{feed}}.padding(.vertical,16).padding(.horizontal,28)
                    }.padding(.bottom,28)}
                }.frame(height:g.size.height*0.8).frame(maxWidth:.infinity).background(surface,in:MemoryDrawerShape(radius:48)).overlay(alignment:rtl ? .topLeading:.topTrailing){Button(action:onClose){MemoryIcon(name:"close",size:16).frame(width:32,height:32)}.padding(.top,20).padding(rtl ? .leading:.trailing,20).accessibilityLabel(t("teams_drawer_close","Close")).accessibilityIdentifier("teamsClose")}.overlay{MemoryDrawerShape(radius:48).stroke(c(light ? "604d38":"94a3b8").opacity(light ? 0.3:0.42),lineWidth:3).padding(1.5).padding(.bottom,-3).allowsHitTesting(false)}.accessibilityElement(children:.contain).accessibilityIdentifier("teamsDrawer").accessibilityHidden(editor != nil)
                    .gesture(DragGesture(minimumDistance:30).onEnded{v in if v.startLocation.y<28,v.translation.height>70{onClose()}})
                if let editor{editorDialog(editor,width:g.size.width).frame(maxHeight:.infinity)}
            }.frame(width:g.size.width,height:g.size.height)
        }.ignoresSafeArea(.container).foregroundStyle(ink).font(.system(size:16)).buttonStyle(TeamsButtonStyle()).environment(\.layoutDirection,rtl ? .rightToLeft:.leftToRight).accessibilityAddTraits(.isModal)
            .task(id:app.identity.npub+app.identity.sessionRevision.uuidString){await model.reload(app);if tab == 1{await model.loadFeed(app)}}
            .onAppear{mounted=true;viewedInvites()}.onReceive(app.teamsStartup.$attention){value in if value.count>0,value.hasUnseen{Task{@MainActor in await Task.yield();viewedInvites()}}}
            .onReceive(app.teamsStartup.$invites){values in if let values{model.applyInvites(values,app:app)}}
            .onChange(of:editor){_,value in field=value?.isRename == true ? "teamEditName":nil}
            .onChange(of:app.localPracticeRevision){_,_ in model.scheduleSharing(app)}
            .onChange(of:LearningTeams.snapshot(app.learner).setting("updatedAt",.number(0)).canonicalJSON){_,_ in model.scheduleSharing(app)}
            .onChange(of:removal){_,value in app.teamsNotices.cover(value != nil,by:confirmationOwner)}
            .onDisappear{mounted=false;model.cancel();app.teamsNotices.cover(false,by:confirmationOwner)}
            .toolbar{ToolbarItemGroup(placement:.keyboard){Spacer();Button("Done"){field=nil}.accessibilityIdentifier("teamsKeyboardDone")}}
            .confirmationDialog(removal?["isCreator"].boolean == true ? t("teams_view_delete_confirm","Delete {team}?").replacingOccurrences(of:"{team}",with:removal?["teamName"].string ?? ""):t("teams_view_leave_confirm","Leave {team}?").replacingOccurrences(of:"{team}",with:removal?["teamName"].string ?? ""),isPresented:Binding(get:{removal != nil},set:{if !$0{removal=nil}}),titleVisibility:.visible){if let team=removal{Button(team["isCreator"].boolean ? t("teams_view_delete","Delete team"):t("teams_view_leave","Leave team"),role:.destructive){model.perform(app,action:{access in try await access.remove(team,app:app);return .init(title:t(team["isCreator"].boolean ? "teams_view_deleted":"teams_view_left",team["isCreator"].boolean ? "Team deleted":"Left team"))});removal=nil}}}
    }
    private func viewedInvites(){if mounted,tab == 0,app.teamsStartup.attention.count>0,app.teamsStartup.attention.hasUnseen{app.teamsStartup.viewed(app)}}
    private func tabButton(_ index:Int,_ title:String)->some View{
        Button{tab=index;if index == 0{app.teamsStartup.viewed(app)};if index == 1{Task{await model.loadFeed(app)}}else{Task{await model.reload(app)}}}label:{text(title).font(.system(size:14,weight:.semibold)).foregroundStyle(tab == index ? ink:(light ? c("8d7a67"):c("a3b4c9"))).frame(height:21).padding(.bottom,8).overlay(alignment:.bottom){if tab == index{Rectangle().fill(LinearGradient(colors:[c("76e4f7"),c("38b2ac")],startPoint:.leading,endPoint:.trailing)).frame(height:2)}}}.accessibilityIdentifier(index == 0 ? "teamsTab":"teamsFeedTab").accessibilityAddTraits(tab == index ? .isSelected:[])
    }
    @ViewBuilder private var teamList:some View {
        HStack(spacing:8){Spacer(minLength:0);action(t("teams_create_open","Create team"),id:"teamCreateOpen"){open(.create)};action(t("teams_copy_id","Copy Your ID"),outline:true,id:"teamsCopyID"){UIPasteboard.general.string=app.identity.npub;app.showTeamsNotice(.init(title:t("teams_copy_id_success","Your ID was copied"),duration:2,closable:true))}.accessibilityValue(app.identity.npub)}
        if let error=model.sharingError{text("Your Score and companion have not synced to Nostr: "+error).font(.system(size:14)).foregroundStyle(.orange)}
        if model.loading{TeamsLoadingDots(label:t("teams_view_loading","Loading teams..."),color:light ? muted:c("a0aec0"))}
        if !model.loading,!pending.isEmpty{VStack(alignment:.leading,spacing:12){
            text(t("teams_view_pending","Pending invitations")).bold().frame(height:24)
            ForEach(pending,id:\.canonicalJSON){invite in
                VStack(alignment:.leading,spacing:0){text(invite["teamName"].string).bold().frame(height:24);text(t("teams_view_invited_by","Invited by")+": "+(invite["invitedByName"].string.isEmpty ? invite["invitedBy"].string:invite["invitedByName"].string)).font(.system(size:14)).foregroundStyle(muted).frame(height:21);HStack(spacing:8){Spacer();action(t("teams_view_accept","Accept"),outline:true,size:14,height:32){respond(invite,true)};action(t("teams_view_decline","Decline"),outline:true,size:14,height:32,danger:true){respond(invite,false)}}.padding(.top,12)}.padding(17).background(surface,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(c(light ? "9decf9":"086f83"))}
            }
        }.padding(.bottom,8)}
        if !model.loading{VStack(alignment:.leading,spacing:12){text(t("teams_view_my_teams","My teams")+" (\(model.snapshot.teams.count))").bold().frame(height:24);ForEach(model.snapshot.teams.map{TeamsDisplayRecord(id:LiveTeamsPanelAccess.key($0),value:$0)}){teamCard($0.value)}}.padding(.bottom,model.snapshot.teams.isEmpty ? 0:12)}
    }
    private func teamCard(_ team:JSONValue)->some View {
        let key=LiveTeamsPanelAccess.key(team),single=model.snapshot.teams.count == 1,visible=single || expanded.contains(key)
        return VStack(spacing:0){
            HStack(spacing:8){if team["isCreator"].boolean{Button{open(.rename(team))}label:{Image("Teams-edit").resizable().frame(width:12,height:12).frame(width:24,height:24)}.accessibilityLabel(t("teams_edit_button","Edit team")).accessibilityIdentifier("teamEdit")};Button{if expanded.contains(key){expanded.remove(key)}else{expanded.insert(key)}}label:{HStack(spacing:8){if !single{Image(systemName:visible ? "chevron.up":"chevron.down").font(.system(size:12))};text(team["teamName"].string).bold().lineLimit(1);Spacer(minLength:0)}.frame(minHeight:24)}.accessibilityIdentifier("learningTeamRow")}.padding(.horizontal,16).padding(.vertical,12)
            if visible{VStack(alignment:.leading,spacing:16){
                if team["isCreator"].boolean{HStack{Spacer();action(t("teams_add_member_open","Add new member"),outline:true,id:"teamAddOpen",size:12,height:24){open(.add(team))}}}
                let rows=(model.snapshot.rows[key] ?? []).sorted{$0["isCreator"].boolean && !$1["isCreator"].boolean}
                if !rows.isEmpty{VStack(spacing:16){ForEach(rows.map{TeamsDisplayRecord(id:$0["npub"].string,value:$0)}){memberCard($0.value)}}.padding(.bottom,16)}
                if rows.isEmpty{text(t("teams_view_no_members","No accepted members yet.")).font(.system(size:14)).foregroundStyle(muted)}
                let waiting=team["members"].array.filter{$0["status"].string == "pending"}
                if !waiting.isEmpty{VStack(alignment:.leading,spacing:4){text(t("teams_view_pending_members","Invites waiting")).font(.system(size:14,weight:.bold)).frame(minHeight:21);ForEach(waiting,id:\.canonicalJSON){text($0["npub"].string).font(.system(size:12)).lineSpacing(4).padding(.vertical,2).foregroundStyle(light ? muted:c("879bb4")).fixedSize(horizontal:false,vertical:true)}}}
                HStack{Spacer();Button{removal=team}label:{Image(team["isCreator"].boolean ? "Teams-trash":"Teams-exit").resizable().frame(width:14,height:14).frame(width:32,height:32).foregroundStyle(light ? c("c53030"):c("fc8181")).overlay{Capsule().stroke(light ? c("e53e3e"):c("fc8181"))}}.disabled(model.working).accessibilityLabel(team["isCreator"].boolean ? t("teams_view_delete","Delete team"):t("teams_view_leave","Leave team")).accessibilityIdentifier("teamRemove")}
            }.padding(17)}
        }.background(surface,in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).stroke(cardBorder)}.accessibilityElement(children:.contain).accessibilityIdentifier("teamCard")
    }
    private func memberCard(_ row:JSONValue)->some View {
        VStack(alignment:.leading,spacing:0){
            HStack{text(row["name"].string.isEmpty ? t("teams_view_name_not_set","Name Not Set Yet"):row["name"].string).font(.system(size:16,weight:.semibold));Spacer();text(row["targetLang"].string.uppercased()).font(.system(size:12,weight:.medium)).foregroundStyle(muted)}.frame(height:24).padding(.bottom,12)
            HStack(spacing:8){metric(t("teams_view_score","Score"),String(Int(row["score"].number.rounded())));metric(t("teams_view_proficiency","Proficiency"),row["level"].string.isEmpty ? "—":row["level"].string);metric(t("teams_view_total_xp","Total XP"),number(row["totalXp"]))}.padding(.bottom,16)
            text(t("teams_view_daily_xp","Daily XP")+": \(Int(max(0,min(100,row["progressPercent"].number)).rounded()))%").font(.system(size:14,weight:.semibold)).frame(height:21).padding(.bottom,8)
            wave(row["progressPercent"].number)
            let pet=row["companion"]
            HStack(spacing:12){TeamCompanionStill(type:pet["type"].string).frame(width:64,height:64);VStack(alignment:.leading,spacing:0){text(pet["name"].string.isEmpty ? (pet["type"].string == "ghost" ? "Ghost":pet["type"].string):pet["name"].string).font(.system(size:16,weight:.semibold)).frame(height:24).lineLimit(1);text(pet["type"].string.capitalized+" · "+t("teams_view_companion_level","Level")+" "+number(pet["level"])).font(.system(size:12)).foregroundStyle(muted).frame(height:18).padding(.bottom,8);HStack(spacing:8){text(t("teams_view_companion_health","Health")).font(.system(size:12)).foregroundStyle(muted);wave(pet["health"].number,blue:true);text(number(pet["health"])+"%").font(.system(size:12,weight:.medium)).frame(height:18)}}}.padding(13).background(light ? surface:.white.opacity(0.04),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(light ? border:.white.opacity(0.06))}.padding(.top,16)
        }.padding(13).background(light ? c("fffdf9"):.white.opacity(0.04),in:RoundedRectangle(cornerRadius:12)).overlay{RoundedRectangle(cornerRadius:12).stroke(cardBorder)}.accessibilityElement(children:.contain).accessibilityIdentifier("teamMember")
    }
    private func metric(_ label:String,_ value:String)->some View{VStack(alignment:.leading,spacing:0){text(label).font(.system(size:12)).foregroundStyle(muted).frame(height:18).lineLimit(1);text(value).font(.system(size:16,weight:.bold)).frame(height:24).lineLimit(1)}.frame(maxWidth:.infinity,alignment:.leading).padding(8).background(light ? surface:.white.opacity(0.06),in:RoundedRectangle(cornerRadius:8))}
    private func wave(_ percent:Double,blue:Bool=false)->some View{FocusWaveBar(percent:percent,start:blue ? "60a5fa":"fbbf24",end:blue ? "38bdf8":"f59e0b",background:.white.opacity(light ? 0.58:0.22),border:light ? c("5b4b3a").opacity(0.1):.white.opacity(0.14)).environment(\.layoutDirection,.leftToRight)}
    private func number(_ value:JSONValue)->String{value.string.isEmpty ? value.number.formatted(.number.grouping(.never)):value.string}
    private func action(_ title:String,outline:Bool=false,id:String="",size:CGFloat=16,height:CGFloat=40,full:Bool=false,disabled:Bool=false,danger:Bool=false,run:@escaping()->Void)->some View{
        Button(action:run){text(title).font(.system(size:size,weight:.semibold)).fixedSize().padding(.horizontal,size == 12 ? 8:16).frame(maxWidth:full ? .infinity:nil).frame(height:height).foregroundStyle(outline ? (danger ? (light ? c("c53030"):c("fc8181")):ink):.white).background{Capsule().fill(outline ? (light ? c("fffdf9"):c("111827")):c("319795")).shadow(color:model.working || disabled ? .clear:(outline ? (id == "teamsCopyID" ? (light ? c("5b4b3a").opacity(0.28):.white.opacity(0.2)):.clear):c("195e5c")),radius:0,y:4)}.overlay{if outline{Capsule().stroke(danger ? (light ? c("e53e3e"):c("fc8181")):border)}}}.disabled(model.working || disabled).opacity(model.working || disabled ? 0.6:1).accessibilityIdentifier(id)
    }
    private func respond(_ invite:JSONValue,_ accept:Bool){model.perform(app,action:{access in try await access.respond(invite,accept:accept,app:app);return .init(title:t(accept ? "teams_view_invite_accepted":"teams_view_invite_rejected",accept ? "Invite accepted":"Invite declined"))})}
    private func open(_ value:TeamsEditor){editor=value;name=value.team?["teamName"].string ?? "";member="";queued=[];model.error=nil}
    private func addMember(){guard let result=try? model.policy?.run("addMember",.object(["input":.string(member),"members":.array(queued.map(JSONValue.string)),"copy":EntryCopy.interface[language] ?? .object([:])])) else{return};member=result["input"].string;queued=result["members"].array.map(\.string);if result["notice"] != .null{let notice=result["notice"];app.showTeamsNotice(.init(title:notice["title"].string,description:notice["description"].string,status:notice["status"].string))}}
    private func submit(_ value:TeamsEditor){
        let submitted=name.trimmingCharacters(in:.whitespacesAndNewlines),members=queued;field=nil
        model.perform(app,action:{access in switch value{
        case .create:try await access.create(name:submitted,members:members,app:app);return .init(title:t("teams_create_success","Team created"),description:t("teams_create_invites","Teammates can see this team in either app"))
        case .rename(let team):let synced=try await access.rename(team,name:submitted,app:app);return .init(title:t("teams_edit_success","Team renamed"),description:synced ? nil:"The team name changed, but some local copies may still show the old name",status:synced ? "success":"warning")
        case .add(let team):_ = try await access.add(team,members:members,app:app);return .init(title:members.count == 1 ? "Member added":"Members added",description:"The team roster has been updated")
        }},errorTitle:t(value.isRename ? "teams_view_error":"teams_create_error","Error"),onSuccess:{editor=nil})
    }
    private func editorDialog(_ value:TeamsEditor,width:CGFloat)->some View {
        ZStack{
            Color.black.opacity(0.48).ignoresSafeArea().onTapGesture{if !model.working{editor=nil}}
            VStack(alignment:.leading,spacing:0){
                text(value.isRename ? t("teams_edit_heading","Edit team name"):value.isAdd ? t("teams_add_member_heading","Add new member"):t("teams_create_heading","Create a new team")).font(.system(size:20,weight:.semibold)).frame(height:30).padding(.horizontal,32).padding(.top,28).padding(.bottom,value.isRename ? 28:4)
                VStack(alignment:.leading,spacing:16){
                    if !value.isAdd{VStack(alignment:.leading,spacing:8){HStack(spacing:4){text(t("teams_create_name_label","Team name"));if value.isRename{text("*").foregroundStyle(.red)}}.frame(height:24);input(value.isRename ? "":t("teams_create_name_placeholder","e.g., Weekend Study"),text:$name,id:value.isRename ? "teamEditName":"teamName").onChange(of:name){_,new in if value.isRename && new.count>80{name=String(new.prefix(80))}}}}
                    if !value.isRename{
                        VStack(alignment:.leading,spacing:8){text(t("teams_create_member_label","Invite teammates")).frame(height:24);HStack(spacing:8){input(t("teams_create_member_placeholder","Enter their ID"),text:$member,id:"teamMembers").onSubmit(addMember);action(t("teams_create_invite_button","Invite"),outline:true,id:"teamQueue",run:addMember)}}
                        if !queued.isEmpty{VStack(alignment:.leading,spacing:8){text(t("teams_create_members_heading","Members to Invite")+" (\(queued.count))").font(.system(size:14,weight:.bold)).frame(height:21);ForEach(queued,id:\.self){npub in HStack(spacing:0){queuedIdentifier(npub).foregroundStyle(light ? muted:c("b7c5d8")).padding(rtl ? .leading:.trailing,12);Button{queued.removeAll{$0==npub}}label:{Image("Teams-NoticeClose").renderingMode(.template).resizable().frame(width:8,height:8).frame(width:24,height:24)}.accessibilityLabel(t("teams_create_remove","Remove")+" "+npub)}.padding(9).background(light ? surface:c("111827"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(light ? border:c("374151"))}}}}
                    }
                    HStack(spacing:8){if value.isRename{Spacer();Button(t("cancel","Cancel")){editor=nil}.font(.system(size:16,weight:.semibold)).padding(.horizontal,16).frame(height:40).disabled(model.working)};action(value.isRename ? t("teams_edit_save","Save"):value.isAdd ? t("teams_add_member_submit","Add member"):t("teams_create_submit","Create team"),id:value.isRename ? "teamRename":value.isAdd ? "teamAdd":"teamCreate",full:!value.isRename,disabled:value.isRename ? name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty || name.trimmingCharacters(in:.whitespacesAndNewlines)==value.team?["teamName"].string : queued.isEmpty || (!value.isAdd && name.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty)){submit(value)}}
                }.padding(.horizontal,28).padding(.top,value.isRename ? 28:0).padding(.bottom,28)
            }.frame(width:min(width,448),alignment:.leading).background(surface,in:RoundedRectangle(cornerRadius:48)).overlay{RoundedRectangle(cornerRadius:48).stroke(c(light ? "604d38":"94a3b8").opacity(light ? 0.3:0.42),lineWidth:3).padding(1.5)}.overlay(alignment:rtl ? .topLeading:.topTrailing){Button{editor=nil}label:{MemoryIcon(name:"close",size:16).frame(width:32,height:32)}.padding(.top,20).padding(rtl ? .leading:.trailing,20).disabled(model.working).accessibilityLabel(t("close","Close")).accessibilityIdentifier("teamEditorClose")}.accessibilityElement(children:.contain).accessibilityIdentifier("teamEditor")
        }
    }
    @ViewBuilder private func queuedIdentifier(_ npub:String)->some View {
        if rtl {
            // WebKit's one-line RTL clamp clips the Latin prefix at the right,
            // then paints its ellipsis at the physical left. Preserve that source
            // presentation while exposing the complete, unchanged ID to accessibility.
            GeometryReader{g in
                let overflow=(npub as NSString).size(withAttributes:[.font:UIFont.systemFont(ofSize:12)]).width>g.size.width
                Text(npub).font(.system(size:12)).fixedSize(horizontal:true,vertical:false).frame(width:g.size.width,height:18,alignment:.leading).clipped()
                    .overlay(alignment:.leading){if overflow{Text("…").font(.system(size:12)).frame(height:18).background(light ? surface:c("111827")).accessibilityHidden(true)}}
            }.environment(\.layoutDirection,.leftToRight).frame(height:18).accessibilityElement(children:.ignore).accessibilityLabel(npub).accessibilityAddTraits(.isStaticText)
        }else{Text(npub).font(.system(size:12)).lineLimit(1).frame(maxWidth:.infinity,alignment:.leading)}
    }
    private func input(_ placeholder:String,text:Binding<String>,id:String)->some View{TextField("",text:text,prompt:Text(directed(placeholder)).foregroundStyle(light ? c("9b8875"):c("a3b4c9"))).font(.system(size:16)).padding(.horizontal,16).frame(height:40).background(light ? c("efe4d5"):c("111827"),in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).stroke(field == id ? c("3182ce"):border,lineWidth:field == id ? 2:1)}.multilineTextAlignment(rtl ? .trailing:.leading).textInputAutocapitalization(.never).autocorrectionDisabled().focused($field,equals:id).disabled(model.working).onSubmit{field=nil}.accessibilityIdentifier(id).environment(\.layoutDirection,.leftToRight)}
    @ViewBuilder private var feed:some View {
        if model.feedLoading {
            VStack(spacing:12){PublicVoiceOrb(size:88).frame(width:88,height:88);text(t("teams_feed_loading","Syncing with the community...")).font(.system(size:14)).lineSpacing(4).frame(minHeight:21).foregroundStyle(muted)}.frame(maxWidth:.infinity).padding(.vertical,32).accessibilityElement(children:.contain).accessibilityIdentifier("teamsFeedLoading")
        }else if let error=model.feedError {
            feedStatus(error:error)
        }else if model.posts.isEmpty {
            feedStatus(error:nil)
        }else {
            ForEach(model.posts){post in
                let profile:JSONValue = .object(["pubkey":.string(post.event.pubkey),"content":.string(post.event.content),"tags":.array(post.event.tags.map{.array($0.map(JSONValue.string))})])
                let card=(try? model.policy?.run("feedCard",.object(["profile":profile]))) ?? .null
                if card != .null{feedCard(post,profile:profile,card:card)}
            }
        }
    }
    private func feedStatus(error:String?)->some View {
        VStack(alignment:.leading,spacing:8){
            text(error ?? t("teams_feed_empty","No posts yet. Start the conversation!")).font(.system(size:14)).lineSpacing(4).padding(.vertical,2).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,minHeight:21,alignment:.leading).foregroundStyle(error == nil ? muted:light ? c("8f4a5e"):c("feb2b2")).accessibilityIdentifier(error == nil ? "teamsFeedEmpty":"teamsFeedError")
            if error != nil{Button{Task{await model.loadFeed(app,force:true)}}label:{text(t("teams_feed_refresh","Refresh"))}.buttonStyle(TeamsFeedRefreshStyle()).accessibilityIdentifier("teamsFeedRefresh")}
        }.padding(17).frame(maxWidth:.infinity,alignment:.leading).background(light ? surface:.clear,in:RoundedRectangle(cornerRadius:6)).overlay{RoundedRectangle(cornerRadius:6).strokeBorder(error == nil ? cardBorder:light ? c("c26784").opacity(0.28):c("fc8181"))}
    }
    private func feedCard(_ post:CommunityPost,profile:JSONValue,card:JSONValue)->some View {
        VStack(alignment:rtl ? .trailing:.leading,spacing:0){
            HStack(spacing:12){
                if let asset=try? model.policy?.run("feedAvatar",.object(["profile":profile])).string{BrandArtwork(name:asset).frame(width:32,height:32).clipShape(RoundedRectangle(cornerRadius:14.72))}
                Link(directed(post.name),destination:URL(string:"https://ditto.pub/"+post.npub)!).underline().accessibilityLabel(post.name).foregroundStyle(light ? ink:.white)
            }.frame(maxWidth:.infinity,alignment:.leading).padding(.bottom,8)
            if card["kind"].string == "progress"{
                text(t("teams_feed_total_xp","Total XP")+": "+number(card["totalXP"])).foregroundStyle(ink).frame(minHeight:21).padding(.bottom,card["percent"] == .null ? 16:8)
            }
            if card["percent"] != .null{
                GeometryReader{g in
                    FocusWaveBar(percent:card["percent"].number,start:card["kind"].string == "progress" ? "fbbf24":"43e97b",end:card["kind"].string == "progress" ? "f59e0b":"38f9d7",background:.white.opacity(light ? 0.58:0.22),border:light ? c("5b4b3a").opacity(0.1):.white.opacity(0.14)).environment(\.layoutDirection,.leftToRight).frame(width:g.size.width*0.8)
                }.frame(height:14).padding(.bottom,card["kind"].string == "progress" ? 8:16)
                if card["kind"].string == "progress"{text(t("teams_feed_goal_completion","Goal completion")+": "+number(card["percent"])+"%").font(.system(size:12)).frame(minHeight:18).foregroundStyle(light ? muted:c("b7c5d8")).padding(.bottom,8)}
            }
            Text(feedContent(post.event.content)).lineSpacing(4).padding(.vertical,2).fixedSize(horizontal:false,vertical:true).frame(maxWidth:.infinity,minHeight:21,alignment:rtl ? .trailing:.leading).accessibilityLabel(post.event.content).accessibilityIdentifier("teamsFeedContent")
            Color.clear.frame(height:21)
            Rectangle().fill(cardBorder).frame(height:1)
        }.font(.system(size:14)).foregroundStyle(light ? ink:.white).multilineTextAlignment(rtl ? .trailing:.leading).padding(17).background(light ? Color(red:0.978431,green:0.955882,blue:0.920588):c("111827"),in:RoundedRectangle(cornerRadius:8)).overlay{RoundedRectangle(cornerRadius:8).strokeBorder(cardBorder)}.shadow(color:light ? c("6f5636").opacity(0.08):.clear,radius:9,y:8).accessibilityElement(children:.contain).accessibilityIdentifier("teamsFeedPost")
    }
    /// The source only links literal http(s) URLs; it does not interpret post Markdown.
    private func feedContent(_ content:String)->AttributedString {
        guard let regex=try? NSRegularExpression(pattern:"https?://[^\\s]+") else{return AttributedString(directed(content))}
        var result=AttributedString(rtl ? "\u{200F}":""),cursor=content.startIndex
        for match in regex.matches(in:content,range:NSRange(content.startIndex...,in:content)){
            guard let range=Range(match.range,in:content) else{continue}
            result.append(AttributedString(String(content[cursor..<range.lowerBound])))
            var link=AttributedString(String(content[range]));link.link=URL(string:String(content[range]));link.foregroundColor=light ? c("2f7dd3"):c("4299e1");link.underlineStyle = .single;result.append(link);cursor=range.upperBound
        }
        result.append(AttributedString(String(content[cursor...])+(rtl ? "\u{200F}":"")))
        return result
    }
}
enum TeamsEditor:Equatable {case create,rename(JSONValue),add(JSONValue);var team:JSONValue?{switch self{case .create:nil;case .rename(let team),.add(let team):team}};var isRename:Bool{if case .rename=self{return true};return false};var isAdd:Bool{if case .add=self{return true};return false}}
private struct TeamCompanionStill:View {
    let type:String
    private static let stages=(try? ContentLibrary.load([String:JSONValue].self,name:"companion-stages")) ?? [:]
    private static func color(_ css:String)->Color{
        if css.hasPrefix("#"){return PiyaliBrand.unitColor(css)}
        let values=css.replacingOccurrences(of:"rgba(",with:"").replacingOccurrences(of:")",with:"").split(separator:",").compactMap{Double($0.trimmingCharacters(in:.whitespaces))}
        guard values.count>=3 else{return .clear};return Color(red:values[0]/255,green:values[1]/255,blue:values[2]/255,opacity:values.count>3 ? values[3]:1)
    }
    var body:some View{Canvas{context,size in context.scaleBy(x:size.width/48,y:size.height/48);for rectangle in Self.stages["happy"]?[type].array.first?.array ?? []{let r=rectangle.array;guard r.count==6 else{continue};context.fill(Path(CGRect(x:r[0].number,y:r[1].number,width:r[2].number,height:r[3].number)),with:.color(Self.color(r[4].string).opacity(r[5].number)),style:FillStyle(antialiased:false))}}.accessibilityHidden(true)}
}

private struct TeamsButtonStyle:ButtonStyle {func makeBody(configuration:Configuration)->some View{configuration.label.opacity(configuration.isPressed ? 0.8:1)}}


private struct TeamsLoadingDots:View {
    let label:String,color:Color
    @Environment(\.accessibilityReduceMotion) private var reducedMotion
    @Environment(\.scenePhase) private var phase
    @State private var started=Date()
    private var title:String{label.replacingOccurrences(of:"[.…]+$",with:"",options:.regularExpression)}
    var body:some View {
        TimelineView(.animation(minimumInterval:1/30,paused:reducedMotion || phase != .active)){time in
            HStack(spacing:8){Text(title).font(.system(size:14)).frame(height:21);HStack(spacing:4){ForEach(0..<3){index in
                let elapsed=time.date.timeIntervalSince(started)-Double(index)*0.16,t=elapsed<0 ? 0:elapsed.truncatingRemainder(dividingBy:1),wave=reducedMotion || elapsed<0 || t>=0.6 ? 0:t<=0.3 ? 0.5-0.5*cos(.pi*t/0.3):0.5+0.5*cos(.pi*(t-0.3)/0.3)
                Circle().frame(width:4,height:4).opacity(0.3+0.7*wave).offset(y:-3*wave)
            }}}.foregroundStyle(color).padding(.vertical,32).frame(maxWidth:.infinity)
        }.accessibilityElement(children:.ignore).accessibilityLabel(title).accessibilityIdentifier("teamsLoading")
    }
}

private struct TeamsFeedRefreshStyle:ButtonStyle {
    func makeBody(configuration:Configuration)->some View {
        configuration.label.font(.system(size:14,weight:.semibold)).foregroundStyle(.white).padding(.horizontal,13).frame(height:32).background{Capsule().fill(PiyaliBrand.unitColor(configuration.isPressed ? "66cdaa":"5dade2")).shadow(color:configuration.isPressed ? .clear:PiyaliBrand.unitColor("2f7cf7"),radius:0,y:4)}.offset(y:configuration.isPressed ? 4:0).animation(.easeOut(duration:0.12),value:configuration.isPressed)
    }
}

private struct TeamsDisplayRecord:Identifiable {let id:String,value:JSONValue}
