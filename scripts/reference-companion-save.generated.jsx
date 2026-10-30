import{useCallback}from'react';import{useToast}from'@chakra-ui/react';import{getEffectivePetType}from'/src/utils/petTypes.js';import{normalizeSupportLanguage,DEFAULT_SUPPORT_LANGUAGE}from'/src/constants/languages.js';import{getGermanCopy}from'/src/utils/germanCopy.js';const uiCopy=(lang, copy) => {
  const normalized = normalizeSupportLanguage(lang, DEFAULT_SUPPORT_LANGUAGE);
  if (copy[normalized]) return copy[normalized];
  if (normalized === "de") return getGermanCopy(copy.en) || copy.en;
  return copy.en;
};export default function useCompanionSaveReference(appLanguage,companionLevel,patchUser,description){const toast=useToast(),activeNpub='public-companion-learner',database={},doc=()=>({}),setDoc=()=>Promise.reject(new Error(description));return useCallback((payload, fallbackPetType) => {
      const rawName =
        payload && typeof payload === "object" ? payload.name : payload;
      const rawPetType =
        payload && typeof payload === "object"
          ? payload.petType
          : fallbackPetType;
      const name = String(rawName || "")
        .trim()
        .slice(0, 24);
      const petType = getEffectivePetType(rawPetType, companionLevel);

      // Optimistic local update so the quest panel, goal modal, and
      // celebration all reflect the customization immediately.
      patchUser?.({ dailyGoalPetName: name, dailyGoalPetType: petType });

      if (!activeNpub) return;

      void setDoc(
        doc(database, "users", activeNpub),
        {
          dailyGoalPetName: name,
          dailyGoalPetType: petType,
          updatedAt: new Date().toISOString(),
        },
        { merge: true },
      ).catch((error) => {
        console.error("Failed to save companion customization:", error);
        toast({
          status: "error",
          title: uiCopy(appLanguage, {
            en: "Save failed",
            es: "Error al guardar",
            it: "Salvataggio non riuscito",
            fr: "Echec de l'enregistrement",
            ja: "保存に失敗しました",
            zh: "保存失败",
          }),
          description: String(error?.message || error),
        });
      });
    },[appLanguage,companionLevel,patchUser,toast,description]);}