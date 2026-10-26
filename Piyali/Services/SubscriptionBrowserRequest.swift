import Foundation

struct SubscriptionBrowserRequest:Identifiable {
 enum Kind{case connect,checkout}
 let id=UUID()
 let url:URL,account:String,revision:UUID,kind:Kind
 static func authorizeURL(_ raw:String,web:URL,allowLoopback:Bool=false)throws->URL{
  guard let url=URL(string:raw),url.user == nil,url.password == nil,url.fragment == nil else{throw AppError.message("Invalid Patreon authorization URL.")}
  if allowLoopback,url.scheme == "http",url.host == web.host,url.port == web.port,url.path == "/authorize"{return url}
  let q=URLComponents(url:url,resolvingAgainstBaseURL:false)?.queryItems ?? [],value:(String)->String={name in q.first{$0.name == name}?.value ?? ""}
  guard url.scheme == "https",["patreon.com","www.patreon.com"].contains(url.host ?? ""),url.port == nil,url.path == "/oauth2/authorize",value("response_type") == "code",!value("client_id").isEmpty,value("scope") == "identity",value("state").range(of:"^[A-Za-z0-9_-]{32,128}$",options:.regularExpression) != nil,let callback=URL(string:value("redirect_uri")),callback.scheme == "https",callback.host == web.host,callback.port == web.port,callback.user == nil,callback.password == nil,callback.path == "/api/patreon/callback",callback.query == nil,callback.fragment == nil else{throw AppError.message("Invalid Patreon authorization URL.")};return url
 }
}
