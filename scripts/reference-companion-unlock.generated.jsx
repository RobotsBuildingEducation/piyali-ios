import React from'react';import{Modal,ModalOverlay,ModalContent,ModalBody,VStack,Text,Button}from'@chakra-ui/react';import DailyGoalPetPanel from'/src/components/DailyGoalPetPanel.jsx';import{getCustomizeModalCopy}from'/src/components/companionCustomizeCopy.js';import{normalizeSupportLanguage,DEFAULT_SUPPORT_LANGUAGE}from'/src/constants/languages.js';import{getGermanCopy}from'/src/utils/germanCopy.js';const uiCopy=(lang, copy) => {
  const normalized = normalizeSupportLanguage(lang, DEFAULT_SUPPORT_LANGUAGE);
  if (copy[normalized]) return copy[normalized];
  if (normalized === "de") return getGermanCopy(copy.en) || copy.en;
  return copy.en;
};export default function UnlockReference({language,type='alien',reachedLevel=2,onEquip=()=>{},onKeep=()=>{}}){const appLanguage=language,companionLevel=reachedLevel,companionUnlockModal={type,name:getCustomizeModalCopy(language)[type],unlockLevel:{"ghost":1,"alien":2,"robot":5,"slime":10,"dog":20,"axolotl":40}[type],reachedLevel},nativeOverlayMotionProps=undefined,nativeModalMotionProps=undefined,handleCloseCompanionUnlockModal=onKeep,handleEquipCompanionUnlock=onEquip,DEFAULT_PET_TYPE='ghost';return <Modal
        isOpen={!!companionUnlockModal}
        onClose={handleCloseCompanionUnlockModal}
        returnFocusOnClose={false}
        closeOnOverlayClick={false}
        closeOnEsc={false}
        isCentered
        size="lg"
        motionPreset="none"
      >
        <ModalOverlay
          motionProps={nativeOverlayMotionProps}
          bg="var(--app-overlay)"
        />
        <ModalContent
          motionProps={nativeModalMotionProps}
          bg="linear-gradient(135deg, #0891b2 0%, #06b6d4 42%, #0e7490 100%)"
          color="white"
          borderRadius="2xl"
          boxShadow="0 28px 80px rgba(8, 145, 178, 0.52)"
          maxW={{ base: "90%", sm: "md" }}
        >
          <ModalBody py={10} px={{ base: 5, md: 8 }}>
            <VStack spacing={6} textAlign="center">
              <VStack spacing={2}>
                <Text fontSize={{ base: "2xl", md: "3xl" }} fontWeight="bold">
                  {uiCopy(appLanguage, {
                    en: "{companion} unlocked!",
                    es: "¡Desbloqueaste {companion}!",
                    pt: "{companion} desbloqueado!",
                    it: "{companion} sbloccato!",
                    fr: "{companion} debloque !",
                    ja: "{companion}をアンロック！",
                    hi: "{companion} अनलॉक हुआ!",
                    ar: "{companion} اتفتح!",
                    zh: "{companion} 已解锁！",
                  }).replace("{companion}", companionUnlockModal?.name || "")}
                </Text>
                <Text
                  fontSize="md"
                  opacity={0.9}
                  lineHeight="1.45"
                  whiteSpace="pre-line"
                >
                  {uiCopy(appLanguage, {
                    en: "You reached Level {level}.\nThis companion can join you now.",
                    es: "Llegaste al nivel {level}.\nEste compañero ya puede acompañarte.",
                    pt: "Voce chegou ao nivel {level}.\nEste companheiro ja pode ir com voce.",
                    it: "Hai raggiunto il livello {level}.\nQuesto compagno ora puo unirsi a te.",
                    fr: "Tu as atteint le niveau {level}.\nCe compagnon peut maintenant te rejoindre.",
                    ja: "レベル{level}に到達しました。\nこの相棒を連れていけます。",
                    hi: "आप स्तर {level} पर पहुंच गए।\nयह साथी अब आपके साथ आ सकता है।",
                    ar: "وصلت للمستوى {level}.\nالرفيق ده يقدر ينضم لك دلوقتي.",
                    zh: "你达到了等级 {level}。\n这个伙伴现在可以加入你了。",
                  }).replace(
                    "{level}",
                    String(companionUnlockModal?.unlockLevel || companionLevel),
                  )}
                </Text>
              </VStack>

              <DailyGoalPetPanel
                lang={appLanguage}
                health={100}
                petName={companionUnlockModal?.name || ""}
                petType={companionUnlockModal?.type || DEFAULT_PET_TYPE}
                companionLevel={
                  companionUnlockModal?.reachedLevel || companionLevel
                }
                variant="celebration"
                celebrationTone="unlock"
                showPreview={false}
              />

              <VStack spacing={4} w="100%">
                <Button
                  size="lg"
                  width="100%"
                  bg="white"
                  color="#0e7490"
                  _hover={{ bg: "rgba(255, 255, 255, 0.92)" }}
                  _active={{ bg: "rgba(255, 255, 255, 0.82)" }}
                  onClick={handleEquipCompanionUnlock}
                  fontWeight="bold"
                  fontSize="lg"
                  py={6}
                >
                  {uiCopy(appLanguage, {
                    en: "Equip",
                    es: "Equipar",
                    pt: "Equipar",
                    it: "Equipaggia",
                    fr: "Equiper",
                    ja: "設定する",
                    hi: "लगाएँ",
                    ar: "استخدمه",
                    zh: "装备",
                  })}
                </Button>
                <Button
                  size="md"
                  width="100%"
                  variant="ghost"
                  color="white"
                  _hover={{ bg: "rgba(207, 250, 254, 0.24)" }}
                  onClick={handleCloseCompanionUnlockModal}
                >
                  {uiCopy(appLanguage, {
                    en: "Keep current",
                    es: "Mantener actual",
                    pt: "Manter atual",
                    it: "Mantieni attuale",
                    fr: "Garder l'actuel",
                    ja: "今のまま",
                    hi: "मौजूदा रखें",
                    ar: "خليك على الحالي",
                    zh: "保留当前",
                  })}
                </Button>
              </VStack>
            </VStack>
          </ModalBody>
        </ModalContent>
      </Modal>;}