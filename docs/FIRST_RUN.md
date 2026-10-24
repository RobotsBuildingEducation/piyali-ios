# Companion Continue and account setup

The companion’s Continue action now opens the setup guide before starting-level selection. Got it and tapping outside the guide both acknowledge it and continue to placement if needed. The same native overlay stays mounted during that handoff; the home/menu controls are covered and hidden from accessibility while the dialog is open. Closing placement returns to the current home. The guide can be opened again from Account.

The original account-wide `gettingStartedModalShown` flag is saved locally and in the canonical Firebase user document. It is monotonic: a stale device/profile acknowledgment cannot reset it. Placement prompting follows the source’s account/language ref for the mounted session. The old global placement guard is used only while the canonical language placement map is absent, and clears when a language placement is made. The decision/acknowledgment rules match 72 journeys executed directly from the original App callbacks; those fixtures do not exercise the database writer.

## Native installation and key handling

The native app is already installed. Its guide therefore acknowledges that state and offers sign-in-key backup, instead of requiring browser-install actions. The original five browser installation steps remain under an expandable Web app section, using the original translations, numbered cards and icon roles. A plain web-home link lets native users open those instructions’ destination without including a key in the URL. Original character 39, purple header, neutral cards and Got it action are retained. The short native explanation is localized separately in ten languages; it is an intentional platform adaptation.

Copying a locally held key is explicit and requires device-owner authentication, consistent with the existing native Account backup action. The key is written directly to the local-only iOS clipboard with a two-minute expiry; it is never rendered in the guide, stored in view state, passed through a URL or logged. Failed/cancelled authorization copies nothing. Dismissal, backgrounding and account replacement invalidate pending authorization. Remote-signer accounts see a signer explanation and have no secret-key copy action.

Native tests inject authorization outcomes using disposable UUID-scoped identities, and separately exercise the actual simulator clipboard writer. They verify expiry parameters and denied/cancelled/stale results. These checks do not prove Face ID/passcode interaction on a physical phone or an elapsed two-minute clipboard expiration. Physical authentication remains a device check; it does not block Got it or the learning flow.

## Appearance and source comparison

Starting-level choice now follows the original 48-point squircle/frame, header padding, dog crop, body padding, neutral button edges, selected-row palette and result typography/surfaces. Its height follows actual content up to the available screen height. The original light choice measures 378×324.39 CSS pixels at a 402×874 viewport; visible control spacing is compared independently of native status/home chrome. Both self-assessment pages, retained choices, localized result and external proficiency-test link remain native. The separate `/proficiency` route remains a web link.

The target-owned read-only preview renders the unmodified GettingStarted and Proficiency components with inert completion callbacks, sounds disabled and a **fake non-key string** to expose the original copy-key tile. No web identity is created and that copy tile is not clicked. The original document-language helper supplies RTL context. Source hashes and callback scope are in [the manifest](reference/first-run-manifest.json).

| State | Source, top 720 CSS pixels | Native, including iOS chrome |
|---|---|---|
| Setup/install, light | [Original browser guide](reference/first-run-install-light-402.png) | [Native installed/key guide](native/first-run-guide-light.png), [expanded original web steps](native/first-run-web-light.png) |
| Starting-level choice | [Source](reference/first-run-choice-light-402.png) | [Native](native/first-run-choice-light.png) |
| Self-report/result | [Selected source row](reference/first-run-selected-light-402.png), [A1 result](reference/first-run-result-light-402.png) | [Native result](native/first-run-result-light.png) |
| Arabic dark setup | [Original browser guide](reference/first-run-install-ar-dark-402.png) | [Native adaptation](native/first-run-guide-ar-dark.png) |
| Arabic dark choice/result | [Choice](reference/first-run-choice-ar-dark-402.png), [result](reference/first-run-result-ar-dark-402.png) | [Choice](native/first-run-choice-ar-dark.png), [result](native/first-run-result-ar-dark.png) |

Platform icon/font fallback, fine text/animation geometry and other locales still need broader comparison. The source preview renders these components rather than a signed-in learner’s complete background. This checkpoint does not complete Today’s Focus, the daily-goal/timer chain after introduction, or the remaining account/feature screen designs.
