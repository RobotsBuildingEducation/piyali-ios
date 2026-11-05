import Foundation

/// Native adaptation only. Browser installation steps and account/key labels
/// continue to use the original translated product copy.
enum FirstRunCopy {
    private static let rows:[String:[String]]=[
        "en":["Piyali on your iPhone","Your app is installed. Save your sign-in key to return on another device.","Install the web app","Couldn’t copy your key. Try again.","Your sign-in key stays with your remote signer."],
        "es":["Piyali en tu iPhone","La app ya está instalada. Guarda tu clave de acceso para volver desde otro dispositivo.","Instalar la app web","No se pudo copiar tu clave. Inténtalo de nuevo.","Tu clave de acceso permanece con tu firmante remoto."],
        "pt":["Piyali no seu iPhone","O app está instalado. Guarde sua chave de acesso para entrar em outro dispositivo.","Instalar o app da web","Não foi possível copiar sua chave. Tente novamente.","Sua chave de acesso fica com seu assinador remoto."],
        "fr":["Piyali sur votre iPhone","L’app est installée. Gardez votre clé de connexion pour revenir sur un autre appareil.","Installer l’app web","Impossible de copier votre clé. Réessayez.","Votre clé de connexion reste chez votre signataire distant."],
        "it":["Piyali sul tuo iPhone","L’app è installata. Conserva la chiave di accesso per tornare da un altro dispositivo.","Installa l’app web","Impossibile copiare la chiave. Riprova.","La chiave di accesso rimane con il firmatario remoto."],
        "de":["Piyali auf deinem iPhone","Die App ist installiert. Bewahre deinen Anmeldeschlüssel auf, um dich auf einem anderen Gerät anzumelden.","Web-App installieren","Dein Schlüssel konnte nicht kopiert werden. Versuche es erneut.","Dein Anmeldeschlüssel bleibt bei deinem Remote-Signer."],
        "ja":["iPhoneでPiyali","アプリはインストール済みです。別の端末でもログインできるよう、ログインキーを保管してください。","ウェブアプリをインストール","キーをコピーできませんでした。もう一度お試しください。","ログインキーはリモート署名者が保管します。"],
        "hi":["आपके iPhone पर Piyali","ऐप इंस्टॉल है। किसी दूसरे डिवाइस पर लौटने के लिए अपनी साइन-इन कुंजी सहेजें।","वेब ऐप इंस्टॉल करें","कुंजी कॉपी नहीं हो सकी। फिर कोशिश करें।","आपकी साइन-इन कुंजी आपके रिमोट साइनर के पास रहती है।"],
        "ar":["Piyali على iPhone","التطبيق متثبّت. احتفظ بمفتاح الدخول علشان ترجع من جهاز تاني.","تثبيت تطبيق الويب","مقدرناش ننسخ المفتاح. جرّب تاني.","مفتاح الدخول بيفضل عند الموقّع عن بُعد."],
        "zh":["iPhone上的Piyali","应用已安装。请保存登录密钥，以便在其他设备上登录。","安装网页版应用","无法复制密钥，请重试。","登录密钥由远程签名器保管。"]
    ]
    static func text(_ language:String,_ index:Int)->String {(rows[language] ?? rows["en"]!)[index]}
    static func secretNote(_ language:String)->String {
        let notes=[
            "en":"Keep your secret safe. Anyone with it can access your account.",
            "es":"Mantén tu clave secreta a salvo. Quien la tenga puede acceder a tu cuenta.",
            "pt":"Mantenha sua chave secreta segura. Quem a tiver pode acessar sua conta.",
            "fr":"Gardez votre clé secrète en lieu sûr. Toute personne qui la possède peut accéder à votre compte.",
            "it":"Conserva la chiave segreta al sicuro. Chi la possiede può accedere al tuo account.",
            "de":"Bewahre deinen geheimen Schlüssel sicher auf. Wer ihn besitzt, kann auf dein Konto zugreifen.",
            "ja":"秘密鍵は安全に保管してください。鍵を持つ人は誰でもアカウントにアクセスできます。",
            "hi":"अपनी गुप्त कुंजी सुरक्षित रखें। जिसके पास यह होगी, वह आपके खाते में प्रवेश कर सकता है।",
            "ar":"احتفظ بمفتاحك السري في مكان آمن. أي حد معاه المفتاح يقدر يدخل على حسابك.",
            "zh":"请妥善保管您的私钥。任何持有私钥的人都可以访问您的账户。"
        ]
        return notes[language] ?? notes["en"]!
    }
}
