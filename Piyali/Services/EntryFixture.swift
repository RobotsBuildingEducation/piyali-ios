import Foundation

enum EntryFixture {
    static func configurePreferences() {
        #if DEBUG
        let env=ProcessInfo.processInfo.environment
        guard env["PIYALI_OFFLINE_TESTS"] == "1",let scope=env["PIYALI_TEST_IDENTITY_SCOPE"],UUID(uuidString:scope) != nil,let language=env["PIYALI_ENTRY_INITIAL_LANGUAGE"],LearningLanguages.support.contains(language),let theme=env["PIYALI_ENTRY_INITIAL_THEME"],["light","dark"].contains(theme) else{return}
        let defaults=UserDefaults.standard,key="piyali.qa.entryPreferencesScope"
        // Launch-argument defaults are immutable overrides. Initialize ordinary
        // defaults once so tests can exercise real language/theme changes and
        // preserve their changes on relaunch, using the actual production UI.
        guard defaults.string(forKey:key) != scope else{return}
        defaults.set(language,forKey:"piyali.interfaceLanguage");defaults.set(theme,forKey:"piyali.theme");defaults.set(scope,forKey:key)
        #endif
    }
}
