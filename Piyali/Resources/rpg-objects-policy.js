var PiyaliRPGObjects = (() => {
  var __defProp = Object.defineProperty;
  var __getOwnPropDesc = Object.getOwnPropertyDescriptor;
  var __getOwnPropNames = Object.getOwnPropertyNames;
  var __hasOwnProp = Object.prototype.hasOwnProperty;
  var __export = (target, all) => {
    for (var name in all)
      __defProp(target, name, { get: all[name], enumerable: true });
  };
  var __copyProps = (to, from, except, desc) => {
    if (from && typeof from === "object" || typeof from === "function") {
      for (let key of __getOwnPropNames(from))
        if (!__hasOwnProp.call(to, key) && key !== except)
          __defProp(to, key, { get: () => from[key], enumerable: !(desc = __getOwnPropDesc(from, key)) || desc.enumerable });
    }
    return to;
  };
  var __toCommonJS = (mod) => __copyProps(__defProp({}, "__esModule", { value: true }), mod);

  // <stdin>
  var stdin_exports = {};
  __export(stdin_exports, {
    api: () => api
  });

  // ../nosabos/nosabos/src/data/manualA1Agendas.js
  var FORM_LABEL_PREFIXES = Object.freeze({
    en: "Use in context",
    es: "Usa en contexto",
    pt: "Use em contexto",
    it: "Usa nel contesto",
    fr: "Utilise en contexte",
    de: "Im Kontext verwenden",
    ja: "\u6587\u8108\u306E\u4E2D\u3067\u4F7F\u3046",
    hi: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
    ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
    zh: "\u5728\u8BED\u5883\u4E2D\u4F7F\u7528"
  });
  var formItem = (lessonId, index, form, modes) => ({
    id: `manual-${lessonId}-form-${index + 1}`,
    kind: "vocabulary",
    modes,
    label: Object.fromEntries(
      Object.entries(FORM_LABEL_PREFIXES).map(([lang, prefix]) => [
        lang,
        `${prefix}: ${form}`
      ])
    ),
    goal: `Recognize and produce "${form}"`,
    targetConcept: form,
    targetRole: "form",
    targetForms: [form],
    targetExamples: [form],
    activityBrief: "Establish the meaning and situation for this exact phrase, then ask for one short recognition or production attempt",
    evidence: {
      type: "produce_or_choose",
      criteria: `The learner recognizes or understandably produces "${form}"`
    },
    source: "manual-a1-agenda",
    spanishOnly: true
  });
  var applicationItem = (lessonId, application, modes) => ({
    id: `manual-${lessonId}-application`,
    kind: application.kind || "communication",
    modes,
    label: application.label,
    goal: application.goal,
    targetConcept: application.goal,
    targetRole: "goal",
    targetForms: [],
    targetExamples: application.examples,
    activityBrief: application.activityBrief,
    evidence: {
      type: application.evidenceType || "scenario_response",
      criteria: application.evidence
    },
    source: "manual-a1-agenda",
    spanishOnly: true
  });
  var agenda = (forms, application) => ({ forms, application });
  var MANUAL_A1_AGENDAS = Object.freeze({
    "lesson-a1-5-2": agenda(
      [
        "\xBFqu\xE9 d\xEDa es hoy?",
        "hoy es...",
        "ma\xF1ana es...",
        "ayer fue...",
        "el lunes",
        "los lunes"
      ],
      {
        label: {
          en: "Say what day it is and distinguish one day from a weekly routine",
          es: "Di qu\xE9 d\xEDa es y distingue un d\xEDa de una rutina semanal",
          pt: "Diga que dia \xE9 e diferencie um dia de uma rotina semanal",
          it: "Di che giorno \xE8 e distingui un giorno da una routine settimanale",
          fr: "Dis quel jour on est et distingue un jour d\u2019une routine hebdomadaire",
          de: "Den Wochentag nennen und einen einzelnen Tag von einer Wochenroutine unterscheiden",
          ja: "\u66DC\u65E5\u3092\u8A00\u3044\u3001\u7279\u5B9A\u306E\u4E00\u65E5\u3068\u6BCE\u9031\u306E\u7FD2\u6163\u3092\u533A\u5225\u3059\u308B",
          hi: "\u0926\u093F\u0928 \u092C\u0924\u093E\u090F\u0902 \u0914\u0930 \u0915\u093F\u0938\u0940 \u090F\u0915 \u0926\u093F\u0928 \u0915\u094B \u0938\u093E\u092A\u094D\u0924\u093E\u0939\u093F\u0915 \u0926\u093F\u0928\u091A\u0930\u094D\u092F\u093E \u0938\u0947 \u0905\u0932\u0917 \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
          ar: "\u0627\u0630\u0643\u0631 \u0627\u0644\u064A\u0648\u0645 \u0648\u0645\u064A\u0651\u0632 \u0628\u064A\u0646 \u064A\u0648\u0645 \u0648\u0627\u062D\u062F \u0648\u0631\u0648\u062A\u064A\u0646 \u0623\u0633\u0628\u0648\u0639\u064A",
          zh: "\u8BF4\u51FA\u661F\u671F\u51E0\uFF0C\u5E76\u533A\u5206\u67D0\u4E00\u5929\u548C\u6BCF\u5468\u60EF\u4F8B"
        },
        goal: "Answer what day it is and distinguish one occurrence from a weekly routine",
        examples: ["Hoy es lunes.", "Los lunes estudio."],
        activityBrief: "Ask about today, yesterday, and tomorrow, then contrast one event on Monday with a recurring Monday routine",
        evidence: "The learner gives three correct day answers and uses el lunes and los lunes in the matching contexts"
      }
    ),
    "lesson-a1-5-3": agenda(
      [
        "el lunes voy a...",
        "el martes tengo...",
        "los mi\xE9rcoles...",
        "el fin de semana...",
        "esta semana",
        "la pr\xF3xima semana"
      ],
      {
        label: {
          en: "Describe three plans on different days and ask one follow-up question",
          es: "Describe tres planes en d\xEDas distintos y haz una pregunta de seguimiento",
          pt: "Descreva tr\xEAs planos em dias diferentes e fa\xE7a uma pergunta de seguimento",
          it: "Descrivi tre programmi in giorni diversi e fai una domanda di approfondimento",
          fr: "D\xE9cris trois projets \xE0 des jours diff\xE9rents et pose une question de suivi",
          de: "Drei Pl\xE4ne an verschiedenen Tagen beschreiben und eine R\xFCckfrage stellen",
          ja: "\u7570\u306A\u308B\u66DC\u65E5\u306E\u4E88\u5B9A\u30923\u3064\u8AAC\u660E\u3057\u3001\u78BA\u8A8D\u306E\u8CEA\u554F\u30921\u3064\u3059\u308B",
          hi: "\u0905\u0932\u0917-\u0905\u0932\u0917 \u0926\u093F\u0928\u094B\u0902 \u0915\u0940 \u0924\u0940\u0928 \u092F\u094B\u091C\u0928\u093E\u090F\u0902 \u092C\u0924\u093E\u090F\u0902 \u0914\u0930 \u090F\u0915 \u0905\u0917\u0932\u093E \u0938\u0935\u093E\u0932 \u092A\u0942\u091B\u0947\u0902",
          ar: "\u0635\u0650\u0641 \u062B\u0644\u0627\u062B \u062E\u0637\u0637 \u0641\u064A \u0623\u064A\u0627\u0645 \u0645\u062E\u062A\u0644\u0641\u0629 \u0648\u0627\u0637\u0631\u062D \u0633\u0624\u0627\u0644 \u0645\u062A\u0627\u0628\u0639\u0629 \u0648\u0627\u062D\u062F\u064B\u0627",
          zh: "\u63CF\u8FF0\u4E09\u4E2A\u4E0D\u540C\u65E5\u671F\u7684\u8BA1\u5212\uFF0C\u5E76\u63D0\u51FA\u4E00\u4E2A\u540E\u7EED\u95EE\u9898"
        },
        goal: "Describe three weekly plans on different days and ask one follow-up question",
        examples: ["El lunes voy a trabajar.", "\xBFY el martes?"],
        activityBrief: "Build a three-day weekly plan one day at a time, then require one question about the other person's week",
        evidence: "The learner states three understandable day-plus-plan combinations and asks one relevant day question"
      }
    ),
    "lesson-a1-6-2": agenda(
      [
        "\xBFcu\xE1ndo es tu cumplea\xF1os?",
        "mi cumplea\xF1os es el...",
        "\xBFqu\xE9 fecha es hoy?",
        "hoy es el...",
        "en enero",
        "el cinco de mayo"
      ],
      {
        label: {
          en: "Ask for and give today\u2019s date and one birthday",
          es: "Pregunta y da la fecha de hoy y un cumplea\xF1os",
          pt: "Pergunte e diga a data de hoje e um anivers\xE1rio",
          it: "Chiedi e comunica la data di oggi e un compleanno",
          fr: "Demande et donne la date d\u2019aujourd\u2019hui et un anniversaire",
          de: "Nach dem heutigen Datum und einem Geburtstag fragen und beide nennen",
          ja: "\u4ECA\u65E5\u306E\u65E5\u4ED8\u3068\u8A95\u751F\u65E5\u3092\u5C0B\u306D\u3066\u7B54\u3048\u308B",
          hi: "\u0906\u091C \u0915\u0940 \u0924\u093E\u0930\u0940\u0916 \u0914\u0930 \u090F\u0915 \u091C\u0928\u094D\u092E\u0926\u093F\u0928 \u092A\u0942\u091B\u0947\u0902 \u0914\u0930 \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0627\u0633\u0623\u0644 \u0639\u0646 \u062A\u0627\u0631\u064A\u062E \u0627\u0644\u064A\u0648\u0645 \u0648\u0639\u0646 \u0639\u064A\u062F \u0645\u064A\u0644\u0627\u062F \u0648\u0627\u0630\u0643\u0631\u0647\u0645\u0627",
          zh: "\u8BE2\u95EE\u5E76\u8BF4\u51FA\u4ECA\u5929\u7684\u65E5\u671F\u548C\u4E00\u4E2A\u751F\u65E5"
        },
        goal: "Ask for and give today's date and one birthday",
        examples: ["Hoy es el cinco de mayo.", "Mi cumplea\xF1os es el doce de junio."],
        activityBrief: "Exchange today's date and a fictional birthday, prompting the day and month separately if needed",
        evidence: "The learner asks or answers both date questions with an understandable day and month"
      }
    ),
    "lesson-a1-6-3": agenda(
      [
        "\xBFcu\xE1ndo es...?",
        "es el...",
        "la cita es el...",
        "la fiesta es el...",
        "primero",
        "despu\xE9s"
      ],
      {
        label: {
          en: "Find the event and date in an invitation, then confirm the day",
          es: "Encuentra el evento y la fecha en una invitaci\xF3n y confirma el d\xEDa",
          pt: "Encontre o evento e a data em um convite e confirme o dia",
          it: "Trova l\u2019evento e la data in un invito, poi conferma il giorno",
          fr: "Trouve l\u2019\xE9v\xE9nement et la date dans une invitation, puis confirme le jour",
          de: "Ereignis und Datum in einer Einladung finden und den Tag best\xE4tigen",
          ja: "\u62DB\u5F85\u72B6\u304B\u3089\u884C\u4E8B\u3068\u65E5\u4ED8\u3092\u898B\u3064\u3051\u3001\u66DC\u65E5\u3092\u78BA\u8A8D\u3059\u308B",
          hi: "\u0928\u093F\u092E\u0902\u0924\u094D\u0930\u0923 \u092E\u0947\u0902 \u0915\u093E\u0930\u094D\u092F\u0915\u094D\u0930\u092E \u0914\u0930 \u0924\u093E\u0930\u0940\u0916 \u0916\u094B\u091C\u0947\u0902, \u092B\u093F\u0930 \u0926\u093F\u0928 \u0915\u0940 \u092A\u0941\u0937\u094D\u091F\u093F \u0915\u0930\u0947\u0902",
          ar: "\u0627\u0639\u062B\u0631 \u0639\u0644\u0649 \u0627\u0644\u0645\u0646\u0627\u0633\u0628\u0629 \u0648\u0627\u0644\u062A\u0627\u0631\u064A\u062E \u0641\u064A \u062F\u0639\u0648\u0629 \u062B\u0645 \u0623\u0643\u0651\u062F \u0627\u0644\u064A\u0648\u0645",
          zh: "\u4ECE\u9080\u8BF7\u4E2D\u627E\u51FA\u6D3B\u52A8\u548C\u65E5\u671F\uFF0C\u7136\u540E\u786E\u8BA4\u65E5\u671F"
        },
        goal: "Identify an event and its date in a short invitation, then confirm the day",
        examples: ["La fiesta es el ocho de julio.", "S\xED, es el s\xE1bado."],
        activityBrief: "Present a two-sentence invitation with one event and date, ask for both details, then run one confirmation turn",
        evidence: "The learner identifies the correct event and date and completes the confirmation",
        kind: "comprehension",
        evidenceType: "identify_and_respond"
      }
    ),
    "lesson-a1-7-2": agenda(
      [
        "\xBFqu\xE9 hora es?",
        "es la una",
        "son las...",
        "y cuarto",
        "y media",
        "menos cuarto",
        "a las..."
      ],
      {
        label: {
          en: "Read a three-item schedule and say each time",
          es: "Lee un horario de tres actividades y di cada hora",
          pt: "Leia um hor\xE1rio de tr\xEAs atividades e diga cada hora",
          it: "Leggi un programma di tre attivit\xE0 e di\u2019 ogni orario",
          fr: "Lis un programme de trois activit\xE9s et donne chaque heure",
          de: "Einen Plan mit drei Terminen lesen und jede Uhrzeit nennen",
          ja: "3\u9805\u76EE\u306E\u4E88\u5B9A\u8868\u3092\u8AAD\u307F\u3001\u305D\u308C\u305E\u308C\u306E\u6642\u523B\u3092\u8A00\u3046",
          hi: "\u0924\u0940\u0928 \u0917\u0924\u093F\u0935\u093F\u0927\u093F\u092F\u094B\u0902 \u0915\u0940 \u0938\u092E\u092F-\u0938\u093E\u0930\u0923\u0940 \u092A\u0922\u093C\u0947\u0902 \u0914\u0930 \u0939\u0930 \u0938\u092E\u092F \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0627\u0642\u0631\u0623 \u062C\u062F\u0648\u0644\u064B\u0627 \u0645\u0646 \u062B\u0644\u0627\u062B\u0629 \u0628\u0646\u0648\u062F \u0648\u0627\u0630\u0643\u0631 \u0648\u0642\u062A \u0643\u0644 \u0648\u0627\u062D\u062F",
          zh: "\u9605\u8BFB\u5305\u542B\u4E09\u9879\u6D3B\u52A8\u7684\u65E5\u7A0B\u5E76\u8BF4\u51FA\u6BCF\u4E2A\u65F6\u95F4"
        },
        goal: "Read a three-item daily schedule and state each time",
        examples: ["La clase es a las dos y media.", "La cena es a las ocho."],
        activityBrief: "Present three familiar activities at an hour, half hour, and quarter hour, asking for one time at a time",
        evidence: "The learner correctly states all three scheduled times",
        kind: "comprehension",
        evidenceType: "identify"
      }
    ),
    "lesson-a1-7-3": agenda(
      [
        "\xBFa qu\xE9 hora puedes?",
        "puedo a las...",
        "no puedo a las...",
        "\xBFte va bien...?",
        "s\xED, perfecto",
        "mejor a las..."
      ],
      {
        label: {
          en: "Arrange and reschedule one appointment in a short exchange",
          es: "Acuerda y cambia una cita en un intercambio breve",
          pt: "Marque e remarque um compromisso em uma conversa curta",
          it: "Fissa e sposta un appuntamento in un breve scambio",
          fr: "Fixe puis d\xE9place un rendez-vous dans un court \xE9change",
          de: "In einem kurzen Gespr\xE4ch einen Termin vereinbaren und verschieben",
          ja: "\u77ED\u3044\u3084\u308A\u53D6\u308A\u3067\u4E88\u7D04\u3092\u6C7A\u3081\u3001\u5225\u306E\u6642\u9593\u306B\u5909\u66F4\u3059\u308B",
          hi: "\u091B\u094B\u091F\u0947 \u0938\u0902\u0935\u093E\u0926 \u092E\u0947\u0902 \u090F\u0915 \u092E\u0941\u0932\u093E\u0915\u093E\u0924 \u0924\u092F \u0915\u0930\u0947\u0902 \u0914\u0930 \u0909\u0938\u0915\u093E \u0938\u092E\u092F \u092C\u0926\u0932\u0947\u0902",
          ar: "\u062D\u062F\u0651\u062F \u0645\u0648\u0639\u062F\u064B\u0627 \u062B\u0645 \u063A\u064A\u0651\u0631\u0647 \u0641\u064A \u062D\u0648\u0627\u0631 \u0642\u0635\u064A\u0631",
          zh: "\u5728\u7B80\u77ED\u5BF9\u8BDD\u4E2D\u5B89\u6392\u5E76\u6539\u7EA6\u4E00\u6B21\u89C1\u9762"
        },
        goal: "Arrange, reject, and confirm one appointment time in a short exchange",
        examples: ["\xBFTe va bien a las tres?", "No puedo. Mejor a las cuatro."],
        activityBrief: "Offer one appointment time, require a conflict and alternative, then confirm the new time",
        evidence: "The learner asks about a time, rejects one option, proposes another, and confirms it"
      }
    ),
    "lesson-a1-8-2": agenda(
      [
        "mi madre se llama...",
        "tengo ... hermanos",
        "este es mi...",
        "\xBFqui\xE9n es...?",
        "\xBFtienes hermanos?",
        "vive en..."
      ],
      {
        label: {
          en: "Exchange three facts about close family members",
          es: "Intercambia tres datos sobre familiares cercanos",
          pt: "Troque tr\xEAs informa\xE7\xF5es sobre familiares pr\xF3ximos",
          it: "Scambia tre informazioni sui familiari stretti",
          fr: "\xC9change trois informations sur des proches",
          de: "Drei Angaben \xFCber enge Familienmitglieder austauschen",
          ja: "\u8FD1\u3044\u5BB6\u65CF\u306B\u3064\u3044\u30663\u3064\u306E\u60C5\u5831\u3092\u3084\u308A\u53D6\u308A\u3059\u308B",
          hi: "\u0915\u0930\u0940\u092C\u0940 \u092A\u0930\u093F\u0935\u093E\u0930 \u0915\u0947 \u0938\u0926\u0938\u094D\u092F\u094B\u0902 \u0915\u0947 \u092C\u093E\u0930\u0947 \u092E\u0947\u0902 \u0924\u0940\u0928 \u092C\u093E\u0924\u0947\u0902 \u0938\u093E\u091D\u093E \u0915\u0930\u0947\u0902",
          ar: "\u062A\u0628\u0627\u062F\u0644 \u062B\u0644\u0627\u062B \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0639\u0646 \u0623\u0641\u0631\u0627\u062F \u0627\u0644\u0623\u0633\u0631\u0629 \u0627\u0644\u0645\u0642\u0631\u0651\u0628\u064A\u0646",
          zh: "\u4EA4\u6D41\u5173\u4E8E\u8FD1\u4EB2\u7684\u4E09\u6761\u4FE1\u606F"
        },
        goal: "Exchange three facts about close family members",
        examples: ["Mi madre se llama Ana.", "Tengo dos hermanos."],
        activityBrief: "Ask and answer about a name, number of siblings, and where one family member lives",
        evidence: "The learner gives three understandable family facts and answers or asks one family question"
      }
    ),
    "lesson-a1-8-3": agenda(
      [
        "es el hermano de...",
        "es la hija de...",
        "su madre",
        "sus primos",
        "\xBFqui\xE9n es...?",
        "se llama..."
      ],
      {
        label: {
          en: "Identify three people from their family relationships",
          es: "Identifica a tres personas por sus relaciones familiares",
          pt: "Identifique tr\xEAs pessoas pelas rela\xE7\xF5es familiares",
          it: "Identifica tre persone dalle loro relazioni familiari",
          fr: "Identifie trois personnes gr\xE2ce \xE0 leurs liens familiaux",
          de: "Drei Personen anhand ihrer Familienbeziehungen erkennen",
          ja: "\u5BB6\u65CF\u95A2\u4FC2\u304B\u30893\u4EBA\u3092\u7279\u5B9A\u3059\u308B",
          hi: "\u092A\u093E\u0930\u093F\u0935\u093E\u0930\u093F\u0915 \u0938\u0902\u092C\u0902\u0927\u094B\u0902 \u0938\u0947 \u0924\u0940\u0928 \u0932\u094B\u0917\u094B\u0902 \u0915\u0940 \u092A\u0939\u091A\u093E\u0928 \u0915\u0930\u0947\u0902",
          ar: "\u062D\u062F\u0651\u062F \u062B\u0644\u0627\u062B\u0629 \u0623\u0634\u062E\u0627\u0635 \u0645\u0646 \u062E\u0644\u0627\u0644 \u0639\u0644\u0627\u0642\u0627\u062A\u0647\u0645 \u0627\u0644\u0639\u0627\u0626\u0644\u064A\u0629",
          zh: "\u6839\u636E\u5BB6\u5EAD\u5173\u7CFB\u8BC6\u522B\u4E09\u4E2A\u4EBA"
        },
        goal: "Identify three people from a short family-tree description",
        examples: ["Luis es el hermano de Ana.", "\xBFQui\xE9n es la madre de Luis?"],
        activityBrief: "Describe a four-person family tree with three explicit relationships, then ask who each person is",
        evidence: "The learner correctly identifies three people or relationships",
        kind: "comprehension",
        evidenceType: "identify"
      }
    ),
    "lesson-a1-9-2": agenda(
      [
        "\xBFde qu\xE9 color es?",
        "es rojo / roja",
        "son rojos / rojas",
        "un c\xEDrculo azul",
        "una mesa blanca",
        "claro / oscuro"
      ],
      {
        label: {
          en: "Describe three objects using the correct color ending",
          es: "Describe tres objetos usando la terminaci\xF3n correcta del color",
          pt: "Descreva tr\xEAs objetos usando a termina\xE7\xE3o correta da cor",
          it: "Descrivi tre oggetti usando la desinenza corretta del colore",
          fr: "D\xE9cris trois objets avec la bonne terminaison de couleur",
          de: "Drei Gegenst\xE4nde mit der richtigen Farbendung beschreiben",
          ja: "\u8272\u306E\u8A9E\u5C3E\u3092\u6B63\u3057\u304F\u4F7F\u3063\u30663\u3064\u306E\u7269\u3092\u8AAC\u660E\u3059\u308B",
          hi: "\u0930\u0902\u0917 \u0915\u0947 \u0938\u0939\u0940 \u0930\u0942\u092A \u0915\u093E \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0915\u0947 \u0924\u0940\u0928 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0915\u093E \u0935\u0930\u094D\u0923\u0928 \u0915\u0930\u0947\u0902",
          ar: "\u0635\u0650\u0641 \u062B\u0644\u0627\u062B\u0629 \u0623\u0634\u064A\u0627\u0621 \u0645\u0633\u062A\u062E\u062F\u0645\u064B\u0627 \u0627\u0644\u0646\u0647\u0627\u064A\u0629 \u0627\u0644\u0635\u062D\u064A\u062D\u0629 \u0644\u0644\u0648\u0646",
          zh: "\u4F7F\u7528\u6B63\u786E\u7684\u989C\u8272\u8BCD\u5C3E\u63CF\u8FF0\u4E09\u4EF6\u7269\u54C1"
        },
        goal: "Describe three familiar objects with color words that agree in gender and number",
        examples: ["La mesa es blanca.", "Los libros son rojos."],
        activityBrief: "Present one masculine singular, one feminine singular, and one plural object and ask for its color",
        evidence: "The learner gives three understandable descriptions with the correct color form"
      }
    ),
    "lesson-a1-9-3": agenda(
      [
        "el libro rojo",
        "la puerta roja",
        "los libros rojos",
        "las puertas rojas",
        "\xBFde qu\xE9 color son?"
      ],
      {
        label: {
          en: "Match four color forms to singular and plural nouns",
          es: "Relaciona cuatro formas de color con sustantivos singulares y plurales",
          pt: "Associe quatro formas de cor a substantivos singulares e plurais",
          it: "Abbina quattro forme di colore a nomi singolari e plurali",
          fr: "Associe quatre formes de couleur \xE0 des noms singuliers et pluriels",
          de: "Vier Farbformen Singular- und Pluralnomen zuordnen",
          ja: "4\u3064\u306E\u8272\u306E\u5F62\u3092\u5358\u6570\u30FB\u8907\u6570\u306E\u540D\u8A5E\u306B\u5408\u308F\u305B\u308B",
          hi: "\u0930\u0902\u0917 \u0915\u0947 \u091A\u093E\u0930 \u0930\u0942\u092A\u094B\u0902 \u0915\u094B \u090F\u0915\u0935\u091A\u0928 \u0914\u0930 \u092C\u0939\u0941\u0935\u091A\u0928 \u0938\u0902\u091C\u094D\u091E\u093E\u0913\u0902 \u0938\u0947 \u092E\u093F\u0932\u093E\u090F\u0902",
          ar: "\u0637\u0627\u0628\u0642 \u0623\u0631\u0628\u0639\u0629 \u0623\u0634\u0643\u0627\u0644 \u0644\u0644\u0623\u0644\u0648\u0627\u0646 \u0645\u0639 \u0623\u0633\u0645\u0627\u0621 \u0645\u0641\u0631\u062F\u0629 \u0648\u062C\u0645\u0639",
          zh: "\u5C06\u56DB\u79CD\u989C\u8272\u5F62\u5F0F\u4E0E\u5355\u590D\u6570\u540D\u8BCD\u914D\u5BF9"
        },
        goal: "Match masculine, feminine, singular, and plural color forms to familiar nouns",
        examples: ["el libro rojo", "las puertas rojas"],
        activityBrief: "Give four noun phrases with the color ending missing and ask for the matching form one at a time",
        evidence: "The learner supplies the correct color form in at least three of four noun phrases",
        kind: "comprehension",
        evidenceType: "produce_or_choose"
      }
    ),
    "lesson-a1-10-2": agenda(
      [
        "tengo hambre",
        "tengo sed",
        "quiero...",
        "me gusta...",
        "no me gusta...",
        "para beber..."
      ],
      {
        label: {
          en: "Choose a meal and drink, then state one preference",
          es: "Elige una comida y una bebida y expresa una preferencia",
          pt: "Escolha uma refei\xE7\xE3o e uma bebida e diga uma prefer\xEAncia",
          it: "Scegli un pasto e una bevanda, poi esprimi una preferenza",
          fr: "Choisis un repas et une boisson, puis exprime une pr\xE9f\xE9rence",
          de: "Eine Mahlzeit und ein Getr\xE4nk w\xE4hlen und eine Vorliebe nennen",
          ja: "\u98DF\u4E8B\u3068\u98F2\u307F\u7269\u3092\u9078\u3073\u3001\u597D\u307F\u30921\u3064\u8FF0\u3079\u308B",
          hi: "\u090F\u0915 \u092D\u094B\u091C\u0928 \u0914\u0930 \u092A\u0947\u092F \u091A\u0941\u0928\u0947\u0902, \u092B\u093F\u0930 \u090F\u0915 \u092A\u0938\u0902\u0926 \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0627\u062E\u062A\u0631 \u0648\u062C\u0628\u0629 \u0648\u0634\u0631\u0627\u0628\u064B\u0627 \u062B\u0645 \u0627\u0630\u0643\u0631 \u062A\u0641\u0636\u064A\u0644\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627",
          zh: "\u9009\u62E9\u4E00\u4EFD\u9910\u98DF\u548C\u996E\u6599\uFF0C\u7136\u540E\u8868\u8FBE\u4E00\u4E2A\u504F\u597D"
        },
        goal: "Choose one familiar food and drink and state one preference",
        examples: ["Quiero pan y caf\xE9.", "Me gusta la fruta."],
        activityBrief: "Offer a small breakfast or lunch choice, elicit one food and drink, then ask what the learner likes",
        evidence: "The learner chooses one food and drink and gives one understandable like or dislike"
      }
    ),
    "lesson-a1-10-3": agenda(
      [
        "mi comida favorita es...",
        "me gusta...",
        "me gustan...",
        "prefiero...",
        "no como...",
        "\xBFqu\xE9 te gusta?"
      ],
      {
        label: {
          en: "Exchange two food preferences and one dislike",
          es: "Intercambia dos preferencias de comida y algo que no te gusta",
          pt: "Troque duas prefer\xEAncias alimentares e algo de que n\xE3o gosta",
          it: "Scambia due preferenze alimentari e un cibo che non piace",
          fr: "\xC9change deux pr\xE9f\xE9rences alimentaires et un aliment que tu n\u2019aimes pas",
          de: "Zwei Essensvorlieben und eine Abneigung austauschen",
          ja: "\u98DF\u3079\u7269\u306E\u597D\u307F\u30922\u3064\u3068\u82E6\u624B\u306A\u3082\u306E\u30921\u3064\u4F1D\u3048\u5408\u3046",
          hi: "\u0916\u093E\u0928\u0947 \u0915\u0940 \u0926\u094B \u092A\u0938\u0902\u0926 \u0914\u0930 \u090F\u0915 \u0928\u093E\u092A\u0938\u0902\u0926 \u0938\u093E\u091D\u093E \u0915\u0930\u0947\u0902",
          ar: "\u062A\u0628\u0627\u062F\u0644 \u062A\u0641\u0636\u064A\u0644\u064A\u0646 \u0644\u0644\u0637\u0639\u0627\u0645 \u0648\u0634\u064A\u0626\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627 \u0644\u0627 \u062A\u062D\u0628\u0647",
          zh: "\u4EA4\u6D41\u4E24\u4E2A\u98DF\u7269\u504F\u597D\u548C\u4E00\u4E2A\u4E0D\u559C\u6B22\u7684\u98DF\u7269"
        },
        goal: "Exchange two food preferences and one dislike using singular and plural forms",
        examples: ["Me gusta el pescado.", "Me gustan las frutas."],
        activityBrief: "Ask about a favorite food, a plural food category, and one disliked food, then reverse roles for one question",
        evidence: "The learner uses me gusta and me gustan appropriately and states one dislike"
      }
    ),
    "lesson-a1-11-2": agenda(
      [
        "para m\xED...",
        "quer\xEDa...",
        "me pone...",
        "\xBFqu\xE9 desea?",
        "\xBFalgo m\xE1s?",
        "la cuenta, por favor"
      ],
      {
        label: {
          en: "Order one dish and one drink, then ask for the bill",
          es: "Pide un plato y una bebida y luego solicita la cuenta",
          pt: "Pe\xE7a um prato e uma bebida e depois pe\xE7a a conta",
          it: "Ordina un piatto e una bevanda, poi chiedi il conto",
          fr: "Commande un plat et une boisson, puis demande l\u2019addition",
          de: "Ein Gericht und ein Getr\xE4nk bestellen und danach um die Rechnung bitten",
          ja: "\u6599\u7406\u3068\u98F2\u307F\u7269\u3092\u6CE8\u6587\u3057\u3001\u305D\u306E\u5F8C\u4F1A\u8A08\u3092\u983C\u3080",
          hi: "\u090F\u0915 \u0935\u094D\u092F\u0902\u091C\u0928 \u0914\u0930 \u092A\u0947\u092F \u092E\u0902\u0917\u093E\u090F\u0902, \u092B\u093F\u0930 \u092C\u093F\u0932 \u092E\u093E\u0902\u0917\u0947\u0902",
          ar: "\u0627\u0637\u0644\u0628 \u0637\u0628\u0642\u064B\u0627 \u0648\u0634\u0631\u0627\u0628\u064B\u0627 \u062B\u0645 \u0627\u0637\u0644\u0628 \u0627\u0644\u062D\u0633\u0627\u0628",
          zh: "\u70B9\u4E00\u9053\u83DC\u548C\u4E00\u676F\u996E\u6599\uFF0C\u7136\u540E\u7D22\u8981\u8D26\u5355"
        },
        goal: "Order one dish and one drink and ask for the bill politely",
        examples: ["Para m\xED, el pescado.", "La cuenta, por favor."],
        activityBrief: "Run a waiter-customer exchange with one dish, one drink, an anything-else turn, and a bill request",
        evidence: "The learner orders both items, responds to \xBFalgo m\xE1s?, and asks for the bill"
      }
    ),
    "lesson-a1-11-3": agenda(
      [
        "\xBFme trae la cuenta?",
        "creo que hay un error",
        "\xBFcu\xE1nto es?",
        "pago con tarjeta",
        "pago en efectivo",
        "el cambio",
        "gracias"
      ],
      {
        label: {
          en: "Check a bill, clarify one charge, and choose how to pay",
          es: "Revisa una cuenta, aclara un cargo y elige c\xF3mo pagar",
          pt: "Confira uma conta, esclare\xE7a uma cobran\xE7a e escolha como pagar",
          it: "Controlla il conto, chiarisci un addebito e scegli come pagare",
          fr: "V\xE9rifie l\u2019addition, clarifie un montant et choisis comment payer",
          de: "Eine Rechnung pr\xFCfen, einen Posten kl\xE4ren und die Zahlungsart w\xE4hlen",
          ja: "\u4F1A\u8A08\u3092\u78BA\u8A8D\u3057\u30011\u3064\u306E\u6599\u91D1\u306B\u3064\u3044\u3066\u5C0B\u306D\u3001\u652F\u6255\u3044\u65B9\u6CD5\u3092\u9078\u3076",
          hi: "\u092C\u093F\u0932 \u091C\u093E\u0902\u091A\u0947\u0902, \u090F\u0915 \u0936\u0941\u0932\u094D\u0915 \u0938\u094D\u092A\u0937\u094D\u091F \u0915\u0930\u0947\u0902 \u0914\u0930 \u092D\u0941\u0917\u0924\u093E\u0928 \u0915\u093E \u0924\u0930\u0940\u0915\u093E \u091A\u0941\u0928\u0947\u0902",
          ar: "\u0631\u0627\u062C\u0639 \u0627\u0644\u062D\u0633\u0627\u0628 \u0648\u0627\u0633\u062A\u0648\u0636\u062D \u0631\u0633\u0645\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627 \u0648\u0627\u062E\u062A\u0631 \u0637\u0631\u064A\u0642\u0629 \u0627\u0644\u062F\u0641\u0639",
          zh: "\u6838\u5BF9\u8D26\u5355\u3001\u6F84\u6E05\u4E00\u9879\u6536\u8D39\u5E76\u9009\u62E9\u4ED8\u6B3E\u65B9\u5F0F"
        },
        goal: "Check a simple bill, clarify one charge, and choose how to pay",
        examples: ["Creo que hay un error.", "Pago con tarjeta."],
        activityBrief: "Present a three-item bill with one unexpected charge, answer one clarification, and ask for card or cash",
        evidence: "The learner identifies or questions the unexpected charge and states a payment method"
      }
    ),
    "lesson-a1-12-2": agenda(
      [
        "\xBFqu\xE9 es esto?",
        "esto es...",
        "\xBFd\xF3nde est\xE1...?",
        "est\xE1 en...",
        "hay...",
        "no hay..."
      ],
      {
        label: {
          en: "Identify and locate three classroom objects",
          es: "Identifica y ubica tres objetos del aula",
          pt: "Identifique e localize tr\xEAs objetos da sala de aula",
          it: "Identifica e localizza tre oggetti dell\u2019aula",
          fr: "Identifie et situe trois objets de la classe",
          de: "Drei Gegenst\xE4nde im Klassenzimmer erkennen und lokalisieren",
          ja: "\u6559\u5BA4\u306E\u7269\u30923\u3064\u7279\u5B9A\u3057\u3001\u5834\u6240\u3092\u8A00\u3046",
          hi: "\u0915\u0915\u094D\u0937\u093E \u0915\u0940 \u0924\u0940\u0928 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0914\u0930 \u0909\u0928\u0915\u093E \u0938\u094D\u0925\u093E\u0928 \u092C\u0924\u093E\u090F\u0902",
          ar: "\u062D\u062F\u0651\u062F \u062B\u0644\u0627\u062B\u0629 \u0623\u0634\u064A\u0627\u0621 \u0641\u064A \u0627\u0644\u0641\u0635\u0644 \u0648\u0627\u0630\u0643\u0631 \u0623\u0645\u0627\u0643\u0646\u0647\u0627",
          zh: "\u8BC6\u522B\u5E76\u6307\u51FA\u4E09\u4EF6\u6559\u5BA4\u7269\u54C1\u7684\u4F4D\u7F6E"
        },
        goal: "Identify and locate three familiar classroom objects",
        examples: ["Esto es un cuaderno.", "El l\xE1piz est\xE1 en la mochila."],
        activityBrief: "Present three classroom objects, ask what each is, then ask where two of them are",
        evidence: "The learner names three objects and gives two understandable locations"
      }
    ),
    "lesson-a1-12-3": agenda(
      ["este", "esta", "ese", "esa", "aqu\xED", "all\xED", "\xBFqu\xE9 es eso?"],
      {
        label: {
          en: "Distinguish and name two nearby and two distant objects",
          es: "Distingue y nombra dos objetos cercanos y dos lejanos",
          pt: "Diferencie e nomeie dois objetos pr\xF3ximos e dois distantes",
          it: "Distingui e nomina due oggetti vicini e due lontani",
          fr: "Distingue et nomme deux objets proches et deux \xE9loign\xE9s",
          de: "Zwei nahe und zwei entfernte Gegenst\xE4nde unterscheiden und benennen",
          ja: "\u8FD1\u304F\u306E\u72692\u3064\u3068\u9060\u304F\u306E\u72692\u3064\u3092\u533A\u5225\u3057\u3066\u540D\u524D\u3092\u8A00\u3046",
          hi: "\u092A\u093E\u0938 \u0915\u0940 \u0926\u094B \u0914\u0930 \u0926\u0942\u0930 \u0915\u0940 \u0926\u094B \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0915\u094B \u0905\u0932\u0917 \u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0914\u0930 \u0928\u093E\u092E \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0645\u064A\u0651\u0632 \u0648\u0633\u0645\u0651\u0650 \u0634\u064A\u0626\u064A\u0646 \u0642\u0631\u064A\u0628\u064A\u0646 \u0648\u0634\u064A\u0626\u064A\u0646 \u0628\u0639\u064A\u062F\u064A\u0646",
          zh: "\u533A\u5206\u5E76\u8BF4\u51FA\u4E24\u4E2A\u8FD1\u5904\u548C\u4E24\u4E2A\u8FDC\u5904\u7684\u7269\u54C1"
        },
        goal: "Distinguish and name two nearby and two distant classroom objects",
        examples: ["Este libro est\xE1 aqu\xED.", "Esa mochila est\xE1 all\xED."],
        activityBrief: "Contrast masculine and feminine classroom objects in near and far positions, one object at a time",
        evidence: "The learner chooses an appropriate demonstrative for at least three of four objects"
      }
    ),
    "lesson-a1-13-2": agenda(
      [
        "\xBFd\xF3nde est\xE1...?",
        "est\xE1 en...",
        "encima de",
        "debajo de",
        "al lado de",
        "entre"
      ],
      {
        label: {
          en: "Ask for and give the location of three household objects",
          es: "Pregunta y da la ubicaci\xF3n de tres objetos de la casa",
          pt: "Pergunte e diga a localiza\xE7\xE3o de tr\xEAs objetos da casa",
          it: "Chiedi e indica la posizione di tre oggetti di casa",
          fr: "Demande et indique l\u2019emplacement de trois objets de la maison",
          de: "Nach dem Ort von drei Haushaltsgegenst\xE4nden fragen und ihn angeben",
          ja: "\u5BB6\u306E\u72693\u3064\u306E\u5834\u6240\u3092\u5C0B\u306D\u3066\u7B54\u3048\u308B",
          hi: "\u0918\u0930 \u0915\u0940 \u0924\u0940\u0928 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0915\u093E \u0938\u094D\u0925\u093E\u0928 \u092A\u0942\u091B\u0947\u0902 \u0914\u0930 \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0627\u0633\u0623\u0644 \u0639\u0646 \u0645\u0643\u0627\u0646 \u062B\u0644\u0627\u062B\u0629 \u0623\u0634\u064A\u0627\u0621 \u0641\u064A \u0627\u0644\u0645\u0646\u0632\u0644 \u0648\u0627\u0630\u0643\u0631\u0647",
          zh: "\u8BE2\u95EE\u5E76\u8BF4\u660E\u4E09\u4EF6\u5BB6\u5C45\u7269\u54C1\u7684\u4F4D\u7F6E"
        },
        goal: "Ask for and give the location of three household objects",
        examples: ["\xBFD\xF3nde est\xE1 la llave?", "Est\xE1 encima de la mesa."],
        activityBrief: "Place three familiar objects in different rooms or positions and alternate asking and answering where they are",
        evidence: "The learner asks one location question and gives three correct location phrases"
      }
    ),
    "lesson-a1-13-3": agenda(
      [
        "en la cocina hay...",
        "la cama est\xE1...",
        "a la derecha de",
        "a la izquierda de",
        "delante de",
        "detr\xE1s de"
      ],
      {
        label: {
          en: "Describe two rooms and the location of their furniture",
          es: "Describe dos habitaciones y la ubicaci\xF3n de sus muebles",
          pt: "Descreva dois c\xF4modos e a localiza\xE7\xE3o dos m\xF3veis",
          it: "Descrivi due stanze e la posizione dei mobili",
          fr: "D\xE9cris deux pi\xE8ces et l\u2019emplacement de leurs meubles",
          de: "Zwei R\xE4ume und die Position ihrer M\xF6bel beschreiben",
          ja: "2\u3064\u306E\u90E8\u5C4B\u3068\u5BB6\u5177\u306E\u4F4D\u7F6E\u3092\u8AAC\u660E\u3059\u308B",
          hi: "\u0926\u094B \u0915\u092E\u0930\u094B\u0902 \u0914\u0930 \u0909\u0928\u0915\u0947 \u092B\u0930\u094D\u0928\u0940\u091A\u0930 \u0915\u0947 \u0938\u094D\u0925\u093E\u0928 \u0915\u093E \u0935\u0930\u094D\u0923\u0928 \u0915\u0930\u0947\u0902",
          ar: "\u0635\u0650\u0641 \u063A\u0631\u0641\u062A\u064A\u0646 \u0648\u0645\u0648\u0627\u0642\u0639 \u0627\u0644\u0623\u062B\u0627\u062B \u0641\u064A\u0647\u0645\u0627",
          zh: "\u63CF\u8FF0\u4E24\u4E2A\u623F\u95F4\u53CA\u5176\u4E2D\u5BB6\u5177\u7684\u4F4D\u7F6E"
        },
        goal: "Describe two rooms and locate at least one piece of furniture in each",
        examples: ["En la cocina hay una mesa.", "El sof\xE1 est\xE1 delante de la ventana."],
        activityBrief: "Build a tiny two-room floor plan and ask for one room item and one relative furniture position in each room",
        evidence: "The learner names both rooms and gives two understandable furniture locations"
      }
    ),
    "lesson-a1-14-2": agenda(
      [
        "busco...",
        "quiero probarme...",
        "\xBFtiene esta...?",
        "\xBFqu\xE9 talla?",
        "me queda bien",
        "me queda mal",
        "\xBFcu\xE1nto cuesta?"
      ],
      {
        label: {
          en: "Ask for one clothing item by color and size",
          es: "Pide una prenda por color y talla",
          pt: "Pe\xE7a uma pe\xE7a de roupa por cor e tamanho",
          it: "Chiedi un capo indicando colore e taglia",
          fr: "Demande un v\xEAtement en pr\xE9cisant la couleur et la taille",
          de: "Nach einem Kleidungsst\xFCck in einer bestimmten Farbe und Gr\xF6\xDFe fragen",
          ja: "\u8272\u3068\u30B5\u30A4\u30BA\u3092\u6307\u5B9A\u3057\u3066\u670D\u30921\u7740\u983C\u3080",
          hi: "\u0930\u0902\u0917 \u0914\u0930 \u0906\u0915\u093E\u0930 \u0915\u0947 \u0905\u0928\u0941\u0938\u093E\u0930 \u090F\u0915 \u0915\u092A\u0921\u093C\u093E \u092E\u093E\u0902\u0917\u0947\u0902",
          ar: "\u0627\u0637\u0644\u0628 \u0642\u0637\u0639\u0629 \u0645\u0644\u0627\u0628\u0633 \u0628\u0644\u0648\u0646 \u0648\u0645\u0642\u0627\u0633 \u0645\u062D\u062F\u062F\u064A\u0646",
          zh: "\u6309\u989C\u8272\u548C\u5C3A\u7801\u8BE2\u95EE\u4E00\u4EF6\u8863\u7269"
        },
        goal: "Ask for, try on, and evaluate one clothing item by color and size",
        examples: ["Busco una chaqueta azul.", "Me queda bien."],
        activityBrief: "Run a shop exchange requiring an item, color, size, try-on response, and price question",
        evidence: "The learner requests a specific item, answers the fit question, and asks the price"
      }
    ),
    "lesson-a1-14-3": agenda(
      [
        "llevo...",
        "me pongo...",
        "combina con...",
        "para el fr\xEDo...",
        "para trabajar...",
        "mi ropa favorita..."
      ],
      {
        label: {
          en: "Choose and describe outfits for two situations",
          es: "Elige y describe ropa para dos situaciones",
          pt: "Escolha e descreva roupas para duas situa\xE7\xF5es",
          it: "Scegli e descrivi abiti per due situazioni",
          fr: "Choisis et d\xE9cris des tenues pour deux situations",
          de: "Kleidung f\xFCr zwei Situationen ausw\xE4hlen und beschreiben",
          ja: "2\u3064\u306E\u5834\u9762\u306B\u5408\u3046\u670D\u88C5\u3092\u9078\u3093\u3067\u8AAC\u660E\u3059\u308B",
          hi: "\u0926\u094B \u092A\u0930\u093F\u0938\u094D\u0925\u093F\u0924\u093F\u092F\u094B\u0902 \u0915\u0947 \u0932\u093F\u090F \u0915\u092A\u0921\u093C\u0947 \u091A\u0941\u0928\u0947\u0902 \u0914\u0930 \u0909\u0928\u0915\u093E \u0935\u0930\u094D\u0923\u0928 \u0915\u0930\u0947\u0902",
          ar: "\u0627\u062E\u062A\u0631 \u0648\u0635\u0650\u0641 \u0645\u0644\u0627\u0628\u0633 \u0644\u0645\u0648\u0642\u0641\u064A\u0646",
          zh: "\u4E3A\u4E24\u4E2A\u573A\u666F\u9009\u62E9\u5E76\u63CF\u8FF0\u670D\u88C5"
        },
        goal: "Choose and describe an appropriate outfit for two simple situations",
        examples: ["Para el fr\xEDo, me pongo un abrigo.", "Llevo una camisa azul para trabajar."],
        activityBrief: "Give one weather context and one everyday event, asking what the learner wears and one color detail",
        evidence: "The learner chooses suitable clothing and describes one item in each situation"
      }
    ),
    "lesson-a1-15-2": agenda(
      [
        "me levanto",
        "me ducho",
        "me visto",
        "desayuno",
        "voy a...",
        "a las..."
      ],
      {
        label: {
          en: "Describe a four-step morning routine with a time",
          es: "Describe una rutina matutina de cuatro pasos con una hora",
          pt: "Descreva uma rotina matinal de quatro etapas com um hor\xE1rio",
          it: "Descrivi una routine mattutina di quattro fasi con un orario",
          fr: "D\xE9cris une routine du matin en quatre \xE9tapes avec une heure",
          de: "Eine Morgenroutine mit vier Schritten und einer Uhrzeit beschreiben",
          ja: "\u6642\u523B\u3092\u5165\u308C\u30664\u6BB5\u968E\u306E\u671D\u306E\u7FD2\u6163\u3092\u8AAC\u660E\u3059\u308B",
          hi: "\u0938\u092E\u092F \u0915\u0947 \u0938\u093E\u0925 \u0938\u0941\u092C\u0939 \u0915\u0940 \u091A\u093E\u0930 \u091A\u0930\u0923\u094B\u0902 \u0935\u093E\u0932\u0940 \u0926\u093F\u0928\u091A\u0930\u094D\u092F\u093E \u092C\u0924\u093E\u090F\u0902",
          ar: "\u0635\u0650\u0641 \u0631\u0648\u062A\u064A\u0646\u064B\u0627 \u0635\u0628\u0627\u062D\u064A\u064B\u0627 \u0645\u0646 \u0623\u0631\u0628\u0639 \u062E\u0637\u0648\u0627\u062A \u0645\u0639 \u0630\u0643\u0631 \u0648\u0642\u062A",
          zh: "\u63CF\u8FF0\u5305\u542B\u65F6\u95F4\u7684\u56DB\u6B65\u6668\u95F4\u65E5\u5E38"
        },
        goal: "Describe a four-step morning routine and include at least one time",
        examples: ["Me levanto a las siete.", "Despu\xE9s, me ducho."],
        activityBrief: "Prompt the learner through waking, washing, dressing, eating, and leaving, then ask for one time",
        evidence: "The learner produces four ordered morning actions and one understandable time"
      }
    ),
    "lesson-a1-15-3": agenda(
      [
        "por la ma\xF1ana",
        "luego",
        "despu\xE9s",
        "por la tarde",
        "por la noche",
        "antes de dormir"
      ],
      {
        label: {
          en: "Put five daily events in order from morning to night",
          es: "Ordena cinco actividades diarias de la ma\xF1ana a la noche",
          pt: "Coloque cinco atividades di\xE1rias em ordem da manh\xE3 \xE0 noite",
          it: "Metti in ordine cinque attivit\xE0 quotidiane dalla mattina alla sera",
          fr: "Mets cinq activit\xE9s quotidiennes dans l\u2019ordre du matin au soir",
          de: "F\xFCnf t\xE4gliche Ereignisse vom Morgen bis zum Abend ordnen",
          ja: "\u671D\u304B\u3089\u591C\u307E\u3067\u306E5\u3064\u306E\u65E5\u8AB2\u3092\u9806\u756A\u306B\u4E26\u3079\u308B",
          hi: "\u0938\u0941\u092C\u0939 \u0938\u0947 \u0930\u093E\u0924 \u0924\u0915 \u0915\u0940 \u092A\u093E\u0902\u091A \u0926\u0948\u0928\u093F\u0915 \u0917\u0924\u093F\u0935\u093F\u0927\u093F\u092F\u094B\u0902 \u0915\u094B \u0915\u094D\u0930\u092E \u092E\u0947\u0902 \u0930\u0916\u0947\u0902",
          ar: "\u0631\u062A\u0651\u0628 \u062E\u0645\u0633\u0629 \u0623\u0646\u0634\u0637\u0629 \u064A\u0648\u0645\u064A\u0629 \u0645\u0646 \u0627\u0644\u0635\u0628\u0627\u062D \u0625\u0644\u0649 \u0627\u0644\u0644\u064A\u0644",
          zh: "\u6309\u4ECE\u65E9\u5230\u665A\u7684\u987A\u5E8F\u6392\u5217\u4E94\u9879\u65E5\u5E38\u6D3B\u52A8"
        },
        goal: "Sequence five daily events from morning to night using time-of-day connectors",
        examples: ["Por la ma\xF1ana desayuno.", "Despu\xE9s trabajo.", "Por la noche ceno."],
        activityBrief: "Give five familiar routine actions out of order and ask the learner to rebuild the day with connectors",
        evidence: "The learner places all five events in a logical order and uses at least three time connectors",
        kind: "comprehension",
        evidenceType: "sequence_and_produce"
      }
    ),
    "lesson-a1-16-2": agenda(
      [
        "en primavera...",
        "en verano...",
        "en oto\xF1o...",
        "en invierno...",
        "hace...",
        "est\xE1..."
      ],
      {
        label: {
          en: "Compare the weather in two seasons",
          es: "Compara el tiempo en dos estaciones",
          pt: "Compare o tempo em duas esta\xE7\xF5es",
          it: "Confronta il tempo in due stagioni",
          fr: "Compare le temps pendant deux saisons",
          de: "Das Wetter in zwei Jahreszeiten vergleichen",
          ja: "2\u3064\u306E\u5B63\u7BC0\u306E\u5929\u6C17\u3092\u6BD4\u3079\u308B",
          hi: "\u0926\u094B \u090B\u0924\u0941\u0913\u0902 \u0915\u0947 \u092E\u094C\u0938\u092E \u0915\u0940 \u0924\u0941\u0932\u0928\u093E \u0915\u0930\u0947\u0902",
          ar: "\u0642\u0627\u0631\u0646 \u0627\u0644\u0637\u0642\u0633 \u0641\u064A \u0641\u0635\u0644\u064A\u0646",
          zh: "\u6BD4\u8F83\u4E24\u4E2A\u5B63\u8282\u7684\u5929\u6C14"
        },
        goal: "Describe and compare the weather in two different seasons",
        examples: ["En verano hace calor.", "En invierno hace fr\xEDo."],
        activityBrief: "Choose two contrasting seasons and ask for one weather expression in each plus one preferred season",
        evidence: "The learner gives an appropriate weather description for both seasons and states a preference"
      }
    ),
    "lesson-a1-16-3": agenda(
      [
        "\xBFqu\xE9 tiempo hace en...?",
        "en ... hace...",
        "hoy",
        "ma\xF1ana",
        "la temperatura",
        "... grados"
      ],
      {
        label: {
          en: "Compare two city forecasts and choose a destination",
          es: "Compara el pron\xF3stico de dos ciudades y elige un destino",
          pt: "Compare a previs\xE3o de duas cidades e escolha um destino",
          it: "Confronta le previsioni di due citt\xE0 e scegli una destinazione",
          fr: "Compare les pr\xE9visions de deux villes et choisis une destination",
          de: "Die Vorhersagen f\xFCr zwei St\xE4dte vergleichen und ein Reiseziel w\xE4hlen",
          ja: "2\u90FD\u5E02\u306E\u5929\u6C17\u4E88\u5831\u3092\u6BD4\u3079\u3001\u884C\u304D\u5148\u3092\u9078\u3076",
          hi: "\u0926\u094B \u0936\u0939\u0930\u094B\u0902 \u0915\u0947 \u092E\u094C\u0938\u092E \u092A\u0942\u0930\u094D\u0935\u093E\u0928\u0941\u092E\u093E\u0928 \u0915\u0940 \u0924\u0941\u0932\u0928\u093E \u0915\u0930\u0947\u0902 \u0914\u0930 \u090F\u0915 \u0917\u0902\u0924\u0935\u094D\u092F \u091A\u0941\u0928\u0947\u0902",
          ar: "\u0642\u0627\u0631\u0646 \u062A\u0648\u0642\u0639\u0627\u062A \u0627\u0644\u0637\u0642\u0633 \u0644\u0645\u062F\u064A\u0646\u062A\u064A\u0646 \u0648\u0627\u062E\u062A\u0631 \u0648\u062C\u0647\u0629",
          zh: "\u6BD4\u8F83\u4E24\u4E2A\u57CE\u5E02\u7684\u5929\u6C14\u9884\u62A5\u5E76\u9009\u62E9\u76EE\u7684\u5730"
        },
        goal: "Compare today's or tomorrow's weather in two cities and choose one destination",
        examples: ["En Madrid hace sol y hay veinte grados.", "Prefiero Madrid."],
        activityBrief: "Present two one-day city forecasts with different conditions and temperatures, then ask which city the learner chooses",
        evidence: "The learner identifies one condition in each city and gives an understandable choice",
        kind: "comprehension",
        evidenceType: "compare_and_choose"
      }
    ),
    "lesson-a1-17-2": agenda(
      [
        "\xBFte gusta...?",
        "me gusta...",
        "me gustan...",
        "me encanta...",
        "a m\xED tambi\xE9n",
        "a m\xED tampoco"
      ],
      {
        label: {
          en: "Exchange three preferences and respond with tambi\xE9n or tampoco",
          es: "Intercambia tres preferencias y responde con tambi\xE9n o tampoco",
          pt: "Troque tr\xEAs prefer\xEAncias e responda com tambi\xE9n ou tampoco",
          it: "Scambia tre preferenze e rispondi con tambi\xE9n o tampoco",
          fr: "\xC9change trois pr\xE9f\xE9rences et r\xE9ponds avec tambi\xE9n ou tampoco",
          de: "Drei Vorlieben austauschen und mit tambi\xE9n oder tampoco reagieren",
          ja: "\u597D\u307F\u30923\u3064\u4F1D\u3048\u5408\u3044\u3001tambi\xE9n \u307E\u305F\u306F tampoco \u3067\u53CD\u5FDC\u3059\u308B",
          hi: "\u0924\u0940\u0928 \u092A\u0938\u0902\u0926 \u0938\u093E\u091D\u093E \u0915\u0930\u0947\u0902 \u0914\u0930 tambi\xE9n \u092F\u093E tampoco \u0938\u0947 \u091C\u0935\u093E\u092C \u0926\u0947\u0902",
          ar: "\u062A\u0628\u0627\u062F\u0644 \u062B\u0644\u0627\u062B\u0629 \u062A\u0641\u0636\u064A\u0644\u0627\u062A \u0648\u0631\u062F\u0651 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 tambi\xE9n \u0623\u0648 tampoco",
          zh: "\u4EA4\u6D41\u4E09\u4E2A\u504F\u597D\uFF0C\u5E76\u7528 tambi\xE9n \u6216 tampoco \u56DE\u5E94"
        },
        goal: "Exchange three likes or dislikes and react with tambi\xE9n or tampoco",
        examples: ["Me gusta leer. \u2014 A m\xED tambi\xE9n.", "No me gusta correr. \u2014 A m\xED tampoco."],
        activityBrief: "Ask about three familiar activities or things, requiring one agreement with tambi\xE9n and one with tampoco",
        evidence: "The learner states three preferences and uses tambi\xE9n and tampoco in matching contexts"
      }
    ),
    "lesson-a1-17-3": agenda(
      [
        "mi ... favorito / favorita es...",
        "prefiero...",
        "odio...",
        "me gusta + infinitivo",
        "me gustan + plural",
        "porque..."
      ],
      {
        label: {
          en: "Explain two favorites and one dislike",
          es: "Explica dos cosas favoritas y algo que no te gusta",
          pt: "Explique duas coisas favoritas e algo de que n\xE3o gosta",
          it: "Spiega due cose preferite e una cosa che non piace",
          fr: "Explique deux choses pr\xE9f\xE9r\xE9es et une chose que tu n\u2019aimes pas",
          de: "Zwei Favoriten und eine Abneigung erkl\xE4ren",
          ja: "\u597D\u304D\u306A\u3082\u306E2\u3064\u3068\u5ACC\u3044\u306A\u3082\u306E1\u3064\u3092\u8AAC\u660E\u3059\u308B",
          hi: "\u0926\u094B \u092A\u0938\u0902\u0926\u0940\u0926\u093E \u091A\u0940\u091C\u093C\u0947\u0902 \u0914\u0930 \u090F\u0915 \u0928\u093E\u092A\u0938\u0902\u0926 \u0938\u092E\u091D\u093E\u090F\u0902",
          ar: "\u0627\u0634\u0631\u062D \u0634\u064A\u0626\u064A\u0646 \u0645\u0641\u0636\u0644\u064A\u0646 \u0648\u0634\u064A\u0626\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627 \u0644\u0627 \u062A\u062D\u0628\u0647",
          zh: "\u8BF4\u660E\u4E24\u4E2A\u6700\u559C\u6B22\u7684\u4E8B\u7269\u548C\u4E00\u4E2A\u4E0D\u559C\u6B22\u7684\u4E8B\u7269"
        },
        goal: "Explain two favorites and one dislike using a noun, a plural, or an infinitive",
        examples: ["Mi comida favorita es la pizza.", "Me gusta bailar porque es divertido."],
        activityBrief: "Ask for a favorite food or object, a favorite activity, and one dislike, prompting a short porque reason once",
        evidence: "The learner states all three preferences and gives one understandable reason"
      }
    ),
    "lesson-a1-18-2": agenda(
      [
        "\xBFqu\xE9...?",
        "\xBFqui\xE9n...?",
        "\xBFd\xF3nde...?",
        "\xBFcu\xE1ndo...?",
        "\xBFc\xF3mo...?",
        "\xBFpor qu\xE9...?",
        "\xBFcu\xE1nto...?"
      ],
      {
        label: {
          en: "Ask five different information questions in a short interview",
          es: "Haz cinco preguntas de informaci\xF3n distintas en una entrevista breve",
          pt: "Fa\xE7a cinco perguntas de informa\xE7\xE3o diferentes em uma entrevista curta",
          it: "Fai cinque domande informative diverse in una breve intervista",
          fr: "Pose cinq questions d\u2019information diff\xE9rentes dans un court entretien",
          de: "In einem kurzen Interview f\xFCnf verschiedene Informationsfragen stellen",
          ja: "\u77ED\u3044\u30A4\u30F3\u30BF\u30D3\u30E5\u30FC\u3067\u7570\u306A\u308B\u60C5\u5831\u8CEA\u554F\u30925\u3064\u3059\u308B",
          hi: "\u091B\u094B\u091F\u0947 \u0938\u093E\u0915\u094D\u0937\u093E\u0924\u094D\u0915\u093E\u0930 \u092E\u0947\u0902 \u092A\u093E\u0902\u091A \u0905\u0932\u0917-\u0905\u0932\u0917 \u091C\u093E\u0928\u0915\u093E\u0930\u0940 \u0935\u093E\u0932\u0947 \u092A\u094D\u0930\u0936\u094D\u0928 \u092A\u0942\u091B\u0947\u0902",
          ar: "\u0627\u0637\u0631\u062D \u062E\u0645\u0633\u0629 \u0623\u0633\u0626\u0644\u0629 \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0645\u062E\u062A\u0644\u0641\u0629 \u0641\u064A \u0645\u0642\u0627\u0628\u0644\u0629 \u0642\u0635\u064A\u0631\u0629",
          zh: "\u5728\u7B80\u77ED\u91C7\u8BBF\u4E2D\u63D0\u51FA\u4E94\u4E2A\u4E0D\u540C\u7684\u4FE1\u606F\u95EE\u9898"
        },
        goal: "Ask five different information questions in a short interview",
        examples: ["\xBFD\xF3nde vives?", "\xBFCu\xE1ndo trabajas?", "\xBFPor qu\xE9 estudias espa\xF1ol?"],
        activityBrief: "Run a five-question interview, requiring a different question word each time and answering each in one short sentence",
        evidence: "The learner forms five understandable questions with five different question words"
      }
    ),
    "lesson-a1-18-3": agenda(
      [
        "\xBFc\xF3mo te llamas?",
        "\xBFde d\xF3nde eres?",
        "\xBFd\xF3nde vives?",
        "\xBFqu\xE9 te gusta?",
        "\xBFcu\xE1ndo...?",
        "\xBFpor qu\xE9...?"
      ],
      {
        label: {
          en: "Complete a five-question personal-information exchange",
          es: "Completa un intercambio de cinco preguntas de informaci\xF3n personal",
          pt: "Complete uma troca de cinco perguntas de informa\xE7\xE3o pessoal",
          it: "Completa uno scambio di cinque domande personali",
          fr: "Compl\xE8te un \xE9change de cinq questions personnelles",
          de: "Einen Austausch mit f\xFCnf Fragen zu pers\xF6nlichen Angaben abschlie\xDFen",
          ja: "\u500B\u4EBA\u60C5\u5831\u306B\u3064\u3044\u30665\u3064\u8CEA\u554F\u3059\u308B\u3084\u308A\u53D6\u308A\u3092\u5B8C\u6210\u3055\u305B\u308B",
          hi: "\u0935\u094D\u092F\u0915\u094D\u0924\u093F\u0917\u0924 \u091C\u093E\u0928\u0915\u093E\u0930\u0940 \u0915\u0947 \u092A\u093E\u0902\u091A \u092A\u094D\u0930\u0936\u094D\u0928\u094B\u0902 \u0935\u093E\u0932\u093E \u0938\u0902\u0935\u093E\u0926 \u092A\u0942\u0930\u093E \u0915\u0930\u0947\u0902",
          ar: "\u0623\u0643\u0645\u0644 \u062D\u0648\u0627\u0631\u064B\u0627 \u0645\u0646 \u062E\u0645\u0633\u0629 \u0623\u0633\u0626\u0644\u0629 \u0639\u0646 \u0627\u0644\u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0634\u062E\u0635\u064A\u0629",
          zh: "\u5B8C\u6210\u5305\u542B\u4E94\u4E2A\u4E2A\u4EBA\u4FE1\u606F\u95EE\u9898\u7684\u4EA4\u6D41"
        },
        goal: "Complete a five-question exchange about name, origin, home, preferences, and routine",
        examples: ["\xBFDe d\xF3nde eres? \u2014 Soy de M\xE9xico.", "\xBFQu\xE9 te gusta? \u2014 Me gusta la m\xFAsica."],
        activityBrief: "Conduct a five-question personal-information exchange with one short answer per question, then switch roles for the final question",
        evidence: "The learner asks or answers five relevant personal-information questions understandably"
      }
    )
  });
  var buildAgenda = (lessonId, spec, modes) => [
    ...spec.forms.map((form, index) => formItem(lessonId, index, form, modes)),
    applicationItem(lessonId, spec.application, modes)
  ];
  function getManualA1AgendaItems(lesson, { modes = null } = {}) {
    const lessonId = typeof lesson === "string" ? lesson : lesson?.id;
    const spec = MANUAL_A1_AGENDAS[lessonId];
    if (!spec) return [];
    const lessonModes = modes || (typeof lesson === "object" && Array.isArray(lesson?.modes) ? lesson.modes : ["vocabulary", "realtime"]);
    return buildAgenda(lessonId, spec, lessonModes);
  }

  // ../nosabos/nosabos/src/data/manualB1B2Agendas.js
  var FORM_LABEL_PREFIXES2 = Object.freeze({
    en: "Use in context",
    es: "Usa en contexto",
    pt: "Use em contexto",
    it: "Usa nel contesto",
    fr: "Utilise en contexte",
    de: "Im Kontext verwenden",
    ja: "\u6587\u8108\u306E\u4E2D\u3067\u4F7F\u3046",
    hi: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
    ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
    zh: "\u5728\u8BED\u5883\u4E2D\u4F7F\u7528"
  });
  var APPLICATION_LABEL_PREFIXES = Object.freeze({
    B1: {
      en: "Complete the connected task",
      es: "Completa la tarea conectada",
      pt: "Complete a tarefa conectada",
      it: "Completa il compito articolato",
      fr: "R\xE9alise la t\xE2che en plusieurs \xE9tapes",
      de: "Die zusammenh\xE4ngende Aufgabe abschlie\xDFen",
      ja: "\u3064\u306A\u304C\u308A\u306E\u3042\u308B\u8AB2\u984C\u3092\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u091C\u0941\u0921\u093C\u093E \u0939\u0941\u0906 \u0915\u093E\u0930\u094D\u092F \u092A\u0942\u0930\u093E \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u0627\u0644\u0645\u0647\u0645\u0629 \u0627\u0644\u0645\u062A\u0631\u0627\u0628\u0637\u0629",
      zh: "\u5B8C\u6210\u8FDE\u8D2F\u4EFB\u52A1"
    },
    B2: {
      en: "Develop and support the response",
      es: "Desarrolla y fundamenta la respuesta",
      pt: "Desenvolva e fundamente a resposta",
      it: "Sviluppa e sostieni la risposta",
      fr: "D\xE9veloppe et justifie la r\xE9ponse",
      de: "Die Antwort entwickeln und begr\xFCnden",
      ja: "\u56DE\u7B54\u3092\u5C55\u958B\u3057\u3001\u6839\u62E0\u3092\u793A\u3059",
      hi: "\u0909\u0924\u094D\u0924\u0930 \u0915\u094B \u0935\u093F\u0915\u0938\u093F\u0924 \u0915\u0930\u0947\u0902 \u0914\u0930 \u0909\u0938\u0915\u093E \u0938\u092E\u0930\u094D\u0925\u0928 \u0915\u0930\u0947\u0902",
      ar: "\u0637\u0648\u0651\u0631 \u0627\u0644\u0625\u062C\u0627\u0628\u0629 \u0648\u0627\u062F\u0639\u0645\u0647\u0627",
      zh: "\u5C55\u5F00\u5E76\u8BBA\u8BC1\u56DE\u7B54"
    }
  });
  var formItem2 = (lessonId, index, form, modes) => ({
    id: `manual-${lessonId}-form-${index + 1}`,
    kind: "vocabulary",
    modes,
    label: Object.fromEntries(
      Object.entries(FORM_LABEL_PREFIXES2).map(([lang, prefix]) => [
        lang,
        `${prefix}: ${form}`
      ])
    ),
    goal: `Recognize and produce "${form}"`,
    targetConcept: form,
    targetRole: "form",
    targetForms: [form],
    targetExamples: [form],
    activityBrief: "Establish the meaning, discourse role, and one natural context for this exact phrase, then elicit a short original use",
    evidence: {
      type: "produce_in_context",
      criteria: `The learner uses "${form}" understandably in a relevant context`
    },
    source: "manual-b1-b2-agenda",
    spanishOnly: true
  });
  var applicationItem2 = (lessonId, spec, modes, forms) => ({
    id: `manual-${lessonId}-application`,
    kind: spec.kind || "communication",
    modes,
    label: Object.fromEntries(
      Object.entries(APPLICATION_LABEL_PREFIXES[spec.level]).map(
        ([lang, prefix]) => [
          lang,
          `${prefix}: ${forms.slice(0, 5).join(" \u2192 ")}`
        ]
      )
    ),
    goal: spec.goal,
    targetConcept: spec.goal,
    targetRole: "goal",
    targetForms: [],
    targetExamples: spec.examples,
    activityBrief: spec.activityBrief,
    evidence: {
      type: spec.evidenceType || "extended_response",
      criteria: spec.evidence
    },
    source: "manual-b1-b2-agenda",
    spanishOnly: true
  });
  var agenda2 = (level, forms, display, goal, examples, activityBrief, evidence, options = {}) => ({
    forms,
    application: {
      level,
      display,
      goal,
      examples,
      activityBrief,
      evidence,
      ...options
    }
  });
  var B1_B2_FOUNDATION_FORMS = Object.freeze({
    "lesson-b1-1-1": [
      "he / has / ha + participio",
      "hemos / han + participio",
      "hecho / dicho",
      "visto / escrito",
      "ya",
      "todav\xEDa no",
      "alguna vez",
      "nunca"
    ],
    "lesson-b1-2-1": [
      "estaba hablando",
      "estabas comiendo",
      "gerundio en -ando",
      "gerundio en -iendo",
      "leyendo",
      "durmiendo",
      "pidiendo",
      "estaba... cuando..."
    ],
    "lesson-b1-3-1": [
      "hablar\xE9 / comer\xE1s / vivir\xE1",
      "tendr\xE9",
      "har\xE9",
      "podr\xE9",
      "saldr\xE9",
      "ma\xF1ana",
      "el a\xF1o que viene",
      "pronto"
    ],
    "lesson-b1-4-1": [
      "m\xE1s / menos... que",
      "tan... como",
      "tanto... como",
      "el / la m\xE1s... de",
      "mejor / peor",
      "mayor / menor",
      "-\xEDsimo / -\xEDsima",
      "ambos / ambas"
    ],
    "lesson-b1-5-1": [
      "deber\xEDas",
      "tendr\xEDas que",
      "podr\xEDas",
      "te recomiendo que",
      "te aconsejo que",
      "lo mejor es que",
      "\xBFpor qu\xE9 no...?",
      "si yo fuera t\xFA..."
    ],
    "lesson-b1-6-1": [
      "\xBFpor qu\xE9 no...?",
      "\xBFqu\xE9 tal si...?",
      "podr\xEDamos",
      "deber\xEDamos",
      "\xBFte parece si...?",
      "vamos a...",
      "hay que...",
      "otra idea ser\xEDa..."
    ],
    "lesson-b1-7-1": [
      "hablar\xEDa / comer\xEDas / vivir\xEDa",
      "tendr\xEDa",
      "har\xEDa",
      "podr\xEDa",
      "me gustar\xEDa",
      "\xBFpodr\xEDas...?",
      "si fuera...",
      "en tu lugar..."
    ],
    "lesson-b1-8-1": [
      "el vuelo",
      "la maleta",
      "el pasaporte",
      "el alojamiento",
      "la reserva",
      "el billete / boleto",
      "la aduana",
      "el embarque"
    ],
    "lesson-b1-9-1": [
      "el medio ambiente",
      "el cambio clim\xE1tico",
      "el reciclaje",
      "la contaminaci\xF3n",
      "los residuos",
      "la energ\xEDa renovable",
      "sostenible",
      "se deber\xEDa..."
    ],
    "lesson-b1-10-1": [
      "la tradici\xF3n",
      "la costumbre",
      "la fiesta / el festival",
      "el desfile",
      "la gastronom\xEDa",
      "celebrar / festejar",
      "disfrazarse",
      "solemos celebrar..."
    ],
    "lesson-b1-11-1": [
      "las noticias",
      "el titular",
      "el reportaje",
      "el peri\xF3dico",
      "la entrevista",
      "la fuente",
      "las redes sociales",
      "seg\xFAn..."
    ],
    "lesson-b1-12-1": [
      "creo que",
      "pienso que",
      "me parece que",
      "en mi opini\xF3n",
      "desde mi punto de vista",
      "estoy de acuerdo",
      "estoy en contra",
      "no creo que"
    ],
    "lesson-b1-13-1": [
      "la queja / el reclamo",
      "el reembolso",
      "no funciona",
      "est\xE1 roto",
      "defectuoso",
      "devolver / cambiar",
      "me gustar\xEDa...",
      "\xBFser\xEDa posible...?"
    ],
    "lesson-b1-14-1": [
      "alguna vez",
      "nunca",
      "una vez",
      "hace... a\xF1os",
      "he probado",
      "he visitado",
      "primero / luego",
      "al final"
    ],
    "lesson-b1-15-1": [
      "quiz\xE1s",
      "tal vez",
      "a lo mejor",
      "probablemente",
      "seguramente",
      "es probable que",
      "es posible que",
      "debe de..."
    ],
    "lesson-b2-1-1": [
      "hab\xEDa hablado",
      "hab\xEDas comido",
      "hab\xEDa + participio",
      "ya hab\xEDa...",
      "todav\xEDa no hab\xEDa...",
      "antes de que...",
      "cuando ocurri\xF3...",
      "para entonces..."
    ],
    "lesson-b2-2-1": [
      "ser + participio + por",
      "fue construido por...",
      "se venden...",
      "se considera...",
      "est\xE1 cerrado / cerrada",
      "fue aprobado / aprobada",
      "se utiliza para...",
      "por parte de..."
    ],
    "lesson-b2-3-1": [
      "dijo que",
      "coment\xF3 que",
      "a\xF1adi\xF3 que",
      "pregunt\xF3 si",
      "pregunt\xF3 qu\xE9 / cu\xE1ndo",
      "pidi\xF3 que",
      "sugiri\xF3 que",
      "aquel d\xEDa / all\xED"
    ],
    "lesson-b2-4-1": [
      "que",
      "quien / quienes",
      "el / la que",
      "el / la cual",
      "cuyo / cuya",
      "donde",
      "con quien",
      "en el que"
    ],
    "lesson-b2-5-1": [
      "t\xFA / usted",
      "hola / buenos d\xEDas",
      "\xBFqu\xE9 tal? / \xBFc\xF3mo est\xE1?",
      "un beso / atentamente",
      "\xBFpuedes...?",
      "\xBFle importar\xEDa...?",
      "quiero... / quisiera...",
      "te env\xEDo... / adjunto..."
    ],
    "lesson-b2-6-1": [
      "la empresa",
      "el departamento",
      "el cargo",
      "el presupuesto",
      "el contrato",
      "el cliente / proveedor",
      "la reuni\xF3n",
      "le agradecer\xEDa que..."
    ],
    "lesson-b2-7-1": [
      "la investigaci\xF3n",
      "el experimento",
      "la hip\xF3tesis",
      "los datos",
      "el descubrimiento",
      "la inteligencia artificial",
      "se demostr\xF3 que",
      "debido a / por lo tanto"
    ],
    "lesson-b2-8-1": [
      "la desigualdad",
      "la pobreza",
      "los derechos",
      "la justicia",
      "la inmigraci\xF3n",
      "la discriminaci\xF3n",
      "la solidaridad",
      "es injusto que..."
    ],
    "lesson-b2-9-1": [
      "la novela / el cuento",
      "el autor / la autora",
      "la obra",
      "la pintura / escultura",
      "el g\xE9nero",
      "la trama",
      "el personaje",
      "se trata de..."
    ],
    "lesson-b2-10-1": [
      "el gobierno",
      "las elecciones",
      "el partido",
      "la ley",
      "el ciudadano / ciudadana",
      "el derecho",
      "votar / gobernar",
      "la democracia"
    ],
    "lesson-b2-11-1": [
      "la salud / el bienestar",
      "la dieta / alimentaci\xF3n",
      "el ejercicio",
      "el estr\xE9s",
      "el descanso",
      "los h\xE1bitos",
      "el sue\xF1o",
      "es bueno que..."
    ],
    "lesson-b2-12-1": [
      "la libertad",
      "la felicidad",
      "la justicia",
      "el \xE9xito",
      "la verdad",
      "el significado",
      "el prop\xF3sito",
      "lo importante / lo dif\xEDcil"
    ]
  });
  var MANUAL_B1_B2_AGENDAS = Object.freeze({
    "lesson-b1-1-2": agenda2(
      "B1",
      [
        "\xBFalguna vez has...?",
        "s\xED, ya he...",
        "no, todav\xEDa no he...",
        "nunca he...",
        "esta semana he...",
        "\xBFcu\xE1ndo fue?",
        "fui / hice..."
      ],
      "\xBFAlguna vez has...? \u2192 he / no he... \u2192 \xBFcu\xE1ndo? \u2192 detalle",
      "Exchange three life experiences and follow one answer with a specific past detail",
      ["\xBFAlguna vez has viajado solo?", "S\xED, fui a Per\xFA el a\xF1o pasado."],
      "Ask about three experiences, require present perfect answers, then move one answer into a dated preterite detail",
      "The learner answers three experience questions and adds one coherent specific-past detail"
    ),
    "lesson-b1-1-3": agenda2(
      "B1",
      [
        "he logrado...",
        "he aprendido...",
        "he terminado...",
        "todav\xEDa no he...",
        "el a\xF1o pasado...",
        "primero...",
        "al final..."
      ],
      "he logrado... \u2192 el a\xF1o pasado... \u2192 primero... \u2192 al final...",
      "Describe one achievement and connect the resulting experience to a specific past sequence",
      ["He aprendido a cocinar.", "El a\xF1o pasado hice mi primer plato."],
      "Prompt one achievement, when it began, two steps in the process, and the final result",
      "The learner distinguishes the current achievement from at least two specific past events"
    ),
    "lesson-b1-2-2": agenda2(
      "B1",
      [
        "estaba + gerundio",
        "mientras...",
        "cuando...",
        "de repente...",
        "llov\xEDa",
        "la gente...",
        "ocurri\xF3..."
      ],
      "estaba... \u2192 mientras... \u2192 de repente... \u2192 ocurri\xF3...",
      "Describe two simultaneous background actions and the event that interrupted them",
      ["Estaba caminando mientras llov\xEDa.", "De repente, ocurri\xF3 un accidente."],
      "Build a three-part scene with two ongoing actions followed by one interrupting event",
      "The learner uses two background actions and one clearly completed interruption"
    ),
    "lesson-b1-2-3": agenda2(
      "B1",
      [
        "era...",
        "estaba...",
        "hab\xEDa...",
        "mientras...",
        "de repente...",
        "entonces...",
        "al final..."
      ],
      "era / estaba / hab\xEDa... \u2192 de repente... \u2192 entonces... \u2192 al final...",
      "Set a past scene and narrate a short event through its conclusion",
      ["Era de noche y hab\xEDa poca gente.", "De repente, se apagaron las luces."],
      "Elicit place, conditions, people, one sudden event, its consequence, and the ending",
      "The learner provides three background details and links the event, consequence, and ending"
    ),
    "lesson-b1-3-2": agenda2(
      "B1",
      [
        "viajar\xE9...",
        "habr\xE1...",
        "llover\xE1...",
        "creo que...",
        "probablemente...",
        "el a\xF1o que viene...",
        "dentro de..."
      ],
      "creo que... \u2192 probablemente... \u2192 habr\xE1 / ser\xE1... \u2192 raz\xF3n",
      "Make three future predictions and explain the reason for one",
      ["Creo que habr\xE1 m\xE1s tecnolog\xEDa.", "Probablemente trabajaremos menos porque..."],
      "Ask for one personal, one social, and one weather or technology prediction, then challenge one with why",
      "The learner produces three future forms and supports one prediction with a reason"
    ),
    "lesson-b1-3-3": agenda2(
      "B1",
      [
        "voy a...",
        "har\xE9...",
        "quiz\xE1s...",
        "ser\xE1...",
        "\xBFqu\xE9 har\xE1s?",
        "depender\xE1 de...",
        "si..., entonces..."
      ],
      "voy a... / har\xE9... \u2192 quiz\xE1s... \u2192 depender\xE1 de... \u2192 si..., entonces...",
      "Distinguish a planned future action from a prediction and a possibility",
      ["Voy a estudiar ma\xF1ana.", "Quiz\xE1s estudiar\xE9 en otro pa\xEDs."],
      "Present a fixed plan, an uncertain possibility, and one condition that could change the result",
      "The learner marks the plan, prediction, and conditional possibility with appropriate forms"
    ),
    "lesson-b1-4-2": agenda2(
      "B1",
      [
        "m\xE1s... que",
        "menos... que",
        "tan... como",
        "mejor / peor",
        "ambos...",
        "en cambio...",
        "prefiero... porque..."
      ],
      "ambos... \u2192 m\xE1s / menos... que \u2192 en cambio... \u2192 prefiero... porque...",
      "Compare two options on three criteria and choose one with a reason",
      ["Ambos son econ\xF3micos.", "Este es m\xE1s r\xE1pido; en cambio, aquel es m\xE1s c\xF3modo."],
      "Give two familiar options and three criteria, requiring one similarity, two contrasts, and a final preference",
      "The learner makes three accurate comparisons and supports a clear choice"
    ),
    "lesson-b1-4-3": agenda2(
      "B1",
      [
        "el / la m\xE1s...",
        "el / la mejor...",
        "el / la peor...",
        "-\xEDsimo / -\xEDsima",
        "de todos...",
        "por un lado...",
        "por otro lado..."
      ],
      "por un lado... \u2192 por otro lado... \u2192 el mejor de... \u2192 elegir\xEDa...",
      "Rank three options and defend the best choice with a balanced comparison",
      ["Es el m\xE1s barato de todos.", "Por otro lado, es lent\xEDsimo."],
      "Ask the learner to rank three options, name one extreme quality, acknowledge a drawback, and select the best",
      "The learner uses a superlative, an intensified adjective, a contrast, and a defended choice"
    ),
    "lesson-b1-5-2": agenda2(
      "B1",
      [
        "deber\xEDas...",
        "podr\xEDas...",
        "te recomiendo que...",
        "lo mejor es que...",
        "\xBFpor qu\xE9 no...?",
        "si yo fuera t\xFA...",
        "porque..."
      ],
      "problema \u2192 deber\xEDas / podr\xEDas... \u2192 te recomiendo que... \u2192 porque...",
      "Give two different pieces of advice and explain which one is best",
      ["Podr\xEDas hablar con ella.", "Te recomiendo que descanses porque..."],
      "Present one everyday problem, elicit a soft option and a stronger recommendation, then ask which is preferable",
      "The learner gives two distinct suggestions and supports the preferred one"
    ),
    "lesson-b1-5-3": agenda2(
      "B1",
      [
        "el problema es que...",
        "una opci\xF3n ser\xEDa...",
        "otra posibilidad es...",
        "la ventaja es...",
        "la desventaja es...",
        "yo que t\xFA...",
        "solucionar\xEDa..."
      ],
      "problema \u2192 dos opciones \u2192 ventaja / desventaja \u2192 yo que t\xFA...",
      "Evaluate two solutions to a problem and make a final recommendation",
      ["Una opci\xF3n ser\xEDa cambiar de horario.", "La desventaja es que cuesta m\xE1s."],
      "Define a problem, compare two possible solutions with one tradeoff each, and close with advice",
      "The learner presents two options, one advantage or disadvantage, and a justified recommendation"
    ),
    "lesson-b1-6-2": agenda2(
      "B1",
      [
        "\xBFqu\xE9 tal si...?",
        "podr\xEDamos...",
        "\xBFte parece si...?",
        "vamos a...",
        "prefiero...",
        "otra idea ser\xEDa...",
        "porque..."
      ],
      "\xBFqu\xE9 tal si...? \u2192 alternativa \u2192 preferencia + raz\xF3n \u2192 acuerdo",
      "Negotiate a shared plan by proposing, revising, and agreeing on an option",
      ["\xBFQu\xE9 tal si vamos el s\xE1bado?", "Prefiero el domingo porque trabajo."],
      "Require an initial suggestion, a conflicting preference, an alternative, and a final agreement",
      "The learner proposes two options, explains one preference, and reaches an explicit agreement"
    ),
    "lesson-b1-6-3": agenda2(
      "B1",
      [
        "me parece bien",
        "vale, de acuerdo",
        "lo siento, pero...",
        "no puedo...",
        "mejor...",
        "entonces quedamos...",
        "\xBFte viene bien?"
      ],
      "propuesta \u2192 rechazo cort\xE9s \u2192 alternativa \u2192 entonces quedamos...",
      "Accept one suggestion, decline another politely, and confirm a revised plan",
      ["Lo siento, pero no puedo el viernes.", "Entonces quedamos el s\xE1bado."],
      "Cycle through one acceptable and one impossible plan, requiring a polite refusal and a confirmed alternative",
      "The learner accepts, declines with a reason, proposes an alternative, and confirms it"
    ),
    "lesson-b1-7-2": agenda2(
      "B1",
      [
        "\xBFpodr\xEDa...?",
        "me gustar\xEDa...",
        "\xBFser\xEDa posible...?",
        "si fuera posible...",
        "har\xEDa...",
        "en tu lugar...",
        "preferir\xEDa..."
      ],
      "petici\xF3n cort\xE9s \u2192 condici\xF3n \u2192 respuesta \u2192 alternativa",
      "Make a polite request, respond to a condition, and offer an alternative",
      ["\xBFSer\xEDa posible cambiar la fecha?", "Si fuera posible, preferir\xEDa el lunes."],
      "Use a service or workplace request that cannot be granted exactly, prompting a conditional alternative",
      "The learner makes a softened request and negotiates one acceptable alternative"
    ),
    "lesson-b1-7-3": agenda2(
      "B1",
      [
        "me encantar\xEDa...",
        "querr\xEDa...",
        "podr\xEDa...",
        "yo que t\xFA...",
        "ser\xEDa mejor...",
        "si tuviera...",
        "elegir\xEDa..."
      ],
      "deseo \u2192 posibilidad \u2192 consejo \u2192 elecci\xF3n hipot\xE9tica",
      "Connect a wish, a hypothetical possibility, and advice in one discussion",
      ["Me encantar\xEDa vivir cerca del mar.", "Si tuviera tiempo, viajar\xEDa m\xE1s."],
      "Ask about one wish, what would make it possible, and what advice the learner would give another person",
      "The learner uses the conditional for a wish, a hypothetical result, and one piece of advice"
    ),
    "lesson-b1-8-2": agenda2(
      "B1",
      [
        "tengo una reserva",
        "quisiera facturar...",
        "\xBFd\xF3nde est\xE1 la puerta...?",
        "el vuelo est\xE1 retrasado",
        "\xBFa qu\xE9 hora sale?",
        "el equipaje de mano",
        "\xBFhay alg\xFAn problema?"
      ],
      "reserva \u2192 equipaje \u2192 puerta / hora \u2192 retraso \u2192 soluci\xF3n",
      "Complete an airport check-in and respond to one travel complication",
      ["Tengo una reserva a nombre de Ruiz.", "\xBFA qu\xE9 hora sale el vuelo?"],
      "Run check-in through reservation, baggage, gate, and departure time, then introduce a delay or baggage issue",
      "The learner completes the check-in information and asks for a relevant solution to the complication"
    ),
    "lesson-b1-8-3": agenda2(
      "B1",
      [
        "quisiera reservar...",
        "\xBFhay disponibilidad?",
        "\xBFqu\xE9 incluye?",
        "la confirmaci\xF3n",
        "\xBFc\xF3mo llego a...?",
        "\xBFqu\xE9 me recomienda?",
        "podr\xEDa visitar..."
      ],
      "reserva \u2192 detalles \u2192 confirmaci\xF3n \u2192 direcci\xF3n \u2192 recomendaci\xF3n",
      "Book accommodation and ask for directions and one local recommendation",
      ["\xBFHay disponibilidad para dos noches?", "\xBFQu\xE9 me recomienda visitar?"],
      "Require dates or duration, included services, confirmation, directions, and one recommendation",
      "The learner secures the key booking details and asks two relevant destination questions"
    ),
    "lesson-b1-9-2": agenda2(
      "B1",
      [
        "hay que...",
        "deber\xEDamos...",
        "se deber\xEDa...",
        "debido a...",
        "por eso...",
        "reducir...",
        "reciclar..."
      ],
      "problema \u2192 debido a... \u2192 por eso... \u2192 dos soluciones",
      "Explain one environmental problem and propose two practical solutions",
      ["Hay contaminaci\xF3n debido al tr\xE1fico.", "Por eso, deber\xEDamos usar el transporte p\xFAblico."],
      "Identify a local cause and consequence, then require one personal and one community solution",
      "The learner links cause and consequence and proposes two distinct actions"
    ),
    "lesson-b1-9-3": agenda2(
      "B1",
      [
        "el problema principal es...",
        "una causa es...",
        "como consecuencia...",
        "una soluci\xF3n ser\xEDa...",
        "propongo que...",
        "porque...",
        "si..., entonces..."
      ],
      "problema \u2192 causa \u2192 consecuencia \u2192 propuesta \u2192 resultado esperado",
      "Present an environmental problem-solution argument with an expected result",
      ["Una causa es el exceso de residuos.", "Si reciclamos m\xE1s, entonces..."],
      "Use a short article scenario to elicit the problem, one cause, one effect, a proposal, and its likely result",
      "The learner produces a coherent five-part problem-solution chain"
    ),
    "lesson-b1-10-2": agenda2(
      "B1",
      [
        "se celebra...",
        "solemos...",
        "cada a\xF1o...",
        "la gente...",
        "durante...",
        "consiste en...",
        "es t\xEDpico..."
      ],
      "cu\xE1ndo se celebra \u2192 qu\xE9 hace la gente \u2192 en qu\xE9 consiste \u2192 por qu\xE9 importa",
      "Describe a celebration through its date, customs, and meaning",
      ["Se celebra cada a\xF1o en agosto.", "La tradici\xF3n consiste en..."],
      "Ask when the celebration occurs, what people usually do, one typical element, and why it matters",
      "The learner gives four connected details about one celebration"
    ),
    "lesson-b1-10-3": agenda2(
      "B1",
      [
        "ambas celebraciones...",
        "mientras que...",
        "a diferencia de...",
        "en cambio...",
        "se parece a...",
        "una tradici\xF3n...",
        "representa..."
      ],
      "semejanza \u2192 mientras que... \u2192 diferencia \u2192 significado",
      "Compare two celebrations and explain one cultural meaning",
      ["Ambas celebraciones re\xFAnen a las familias.", "En cambio, una dura varios d\xEDas."],
      "Present two short cultural descriptions and require one similarity, two differences, and one interpretation",
      "The learner compares both celebrations accurately and explains one meaningful custom"
    ),
    "lesson-b1-11-2": agenda2(
      "B1",
      [
        "seg\xFAn...",
        "dicen que...",
        "informa que...",
        "al parecer...",
        "el titular...",
        "la fuente...",
        "ocurri\xF3..."
      ],
      "titular \u2192 seg\xFAn la fuente... \u2192 qu\xE9 ocurri\xF3 \u2192 reacci\xF3n",
      "Report the main event from a headline and attribute it to a source",
      ["Seg\xFAn el peri\xF3dico, ocurri\xF3 ayer.", "Al parecer, no hubo heridos."],
      "Give a headline and summary, asking for the event, source, one uncertain detail, and a reaction",
      "The learner reports the event, attributes the information, and marks uncertainty appropriately"
    ),
    "lesson-b1-11-3": agenda2(
      "B1",
      [
        "es un hecho que...",
        "seg\xFAn la fuente...",
        "en mi opini\xF3n...",
        "parece que...",
        "no est\xE1 confirmado",
        "sin embargo...",
        "la evidencia..."
      ],
      "hecho \u2192 fuente \u2192 dato no confirmado \u2192 opini\xF3n \u2192 reacci\xF3n",
      "Separate facts, uncertain claims, and opinion in a short news report",
      ["Es un hecho que la reuni\xF3n ocurri\xF3.", "No est\xE1 confirmado qui\xE9n particip\xF3."],
      "Present five statements from a short report and ask the learner to classify and restate each type",
      "The learner identifies at least one fact, one uncertain claim, and one opinion and attributes a source",
      { kind: "comprehension", evidenceType: "classify_and_respond" }
    ),
    "lesson-b1-12-2": agenda2(
      "B1",
      [
        "creo que...",
        "en mi opini\xF3n...",
        "estoy de acuerdo",
        "no estoy de acuerdo",
        "entiendo tu punto, pero...",
        "porque...",
        "por ejemplo..."
      ],
      "opini\xF3n \u2192 raz\xF3n \u2192 ejemplo \u2192 acuerdo / desacuerdo cort\xE9s",
      "State and support an opinion and respond politely to another view",
      ["En mi opini\xF3n, es una buena idea porque...", "Entiendo tu punto, pero..."],
      "Ask for a position, reason, example, and response to one contrasting opinion",
      "The learner supports a clear view and responds to disagreement without abandoning the topic"
    ),
    "lesson-b1-12-3": agenda2(
      "B1",
      [
        "mi argumento es...",
        "la raz\xF3n principal es...",
        "por ejemplo...",
        "sin embargo...",
        "no creo que...",
        "estoy de acuerdo en parte",
        "en conclusi\xF3n..."
      ],
      "argumento \u2192 raz\xF3n + ejemplo \u2192 objeci\xF3n \u2192 respuesta \u2192 conclusi\xF3n",
      "Build a short argument and answer one respectful challenge",
      ["La raz\xF3n principal es el costo.", "Estoy de acuerdo en parte; sin embargo..."],
      "Structure a mini-debate with a claim, support, one challenge supplied by the tutor, and a conclusion",
      "The learner maintains a coherent position through support, concession, response, and conclusion"
    ),
    "lesson-b1-13-2": agenda2(
      "B1",
      [
        "quisiera presentar una queja",
        "no funciona",
        "est\xE1 roto / defectuoso",
        "me gustar\xEDa...",
        "\xBFser\xEDa posible...?",
        "un cambio",
        "un reembolso"
      ],
      "problema espec\xEDfico \u2192 efecto \u2192 petici\xF3n cort\xE9s \u2192 cambio / reembolso",
      "Make a polite complaint and request a specific remedy",
      ["El aparato no funciona.", "\xBFSer\xEDa posible recibir un reembolso?"],
      "Require product or service details, the exact problem, its consequence, and a chosen remedy",
      "The learner describes the problem clearly and makes one appropriately softened request"
    ),
    "lesson-b1-13-3": agenda2(
      "B1",
      [
        "entiendo el problema",
        "lo siento por...",
        "puedo ofrecerle...",
        "preferir\xEDa...",
        "acepto...",
        "no es suficiente",
        "gracias por su ayuda"
      ],
      "queja \u2192 reconocimiento \u2192 oferta \u2192 contraoferta \u2192 acuerdo",
      "Resolve a complaint by evaluating an offer and negotiating an acceptable outcome",
      ["Puedo ofrecerle un cambio.", "Preferir\xEDa un reembolso."],
      "Switch roles through complaint acknowledgment, first offer, customer response, revised offer, and closure",
      "The learner responds to the complaint and negotiates through to an explicit resolution"
    ),
    "lesson-b1-14-2": agenda2(
      "B1",
      [
        "\xBFalguna vez has...?",
        "s\xED, he...",
        "no, nunca he...",
        "\xBFcu\xE1ndo fue?",
        "\xBFqu\xE9 pas\xF3?",
        "primero...",
        "luego..."
      ],
      "experiencia \u2192 cu\xE1ndo \u2192 qu\xE9 pas\xF3 \u2192 primero / luego",
      "Ask about an experience and narrate two specific events from it",
      ["\xBFAlguna vez has perdido un vuelo?", "S\xED. Primero llegu\xE9 tarde y luego..."],
      "Use one experience question, then require time, setting, and two ordered past actions",
      "The learner moves accurately from present perfect experience framing into a specific past narrative"
    ),
    "lesson-b1-14-3": agenda2(
      "B1",
      [
        "hace... a\xF1os",
        "estaba...",
        "de repente...",
        "entonces...",
        "por eso...",
        "al final...",
        "aprend\xED que..."
      ],
      "contexto \u2192 acci\xF3n en curso \u2192 giro \u2192 consecuencia \u2192 aprendizaje",
      "Narrate a memorable experience and explain what was learned",
      ["Hace dos a\xF1os estaba viajando cuando...", "Al final, aprend\xED que..."],
      "Prompt a dated setting, background action, turning point, consequence, ending, and reflection",
      "The learner tells a linked narrative with appropriate past framing and a clear lesson"
    ),
    "lesson-b1-15-2": agenda2(
      "B1",
      [
        "quiz\xE1s est\xE9...",
        "a lo mejor est\xE1...",
        "debe de estar...",
        "es posible que...",
        "no creo que...",
        "probablemente...",
        "porque..."
      ],
      "tres hip\xF3tesis \u2192 grado de certeza \u2192 evidencia \u2192 explicaci\xF3n preferida",
      "Propose three explanations for a puzzling situation and rank their likelihood",
      ["Quiz\xE1s est\xE9 enfermo.", "Debe de estar en casa porque las luces est\xE1n encendidas."],
      "Give a mystery with three clues, require three differently weighted hypotheses, and select the best explanation",
      "The learner expresses three levels of probability and supports the leading hypothesis with evidence"
    ),
    "lesson-b1-15-3": agenda2(
      "B1",
      [
        "seguro que...",
        "seguramente...",
        "probablemente...",
        "quiz\xE1s...",
        "es poco probable que...",
        "dudo que...",
        "no puede ser que..."
      ],
      "seguro \u2192 probable \u2192 posible \u2192 poco probable \u2192 duda",
      "Order five predictions from most to least certain and justify two positions",
      ["Seguramente llegar\xE1 pronto.", "Dudo que llegue hoy."],
      "Present five predictions about one scenario, ask for a certainty ranking, then challenge the top and bottom choices",
      "The learner uses at least four distinct certainty frames and justifies two rankings"
    ),
    "lesson-b2-1-2": agenda2(
      "B2",
      [
        "cuando llegu\xE9, ya hab\xEDa...",
        "antes de...",
        "despu\xE9s de...",
        "todav\xEDa no hab\xEDa...",
        "para entonces...",
        "una vez que...",
        "resulta que..."
      ],
      "resultado \u2192 ya hab\xEDa... \u2192 antes / despu\xE9s \u2192 revelaci\xF3n",
      "Reconstruct an event by distinguishing what had and had not happened beforehand",
      ["Cuando llegu\xE9, ya hab\xEDan salido.", "Para entonces, todav\xEDa no hab\xEDa recibido el mensaje."],
      "Reveal a final situation and four timeline clues, requiring the learner to reconstruct the earlier sequence",
      "The learner orders the prior events and consistently marks their relation to the later reference point"
    ),
    "lesson-b2-1-3": agenda2(
      "B2",
      [
        "anteriormente...",
        "hab\xEDa...",
        "una vez que...",
        "hasta que...",
        "cuando ocurri\xF3...",
        "posteriormente...",
        "finalmente..."
      ],
      "anteriormente \u2192 hab\xEDa... \u2192 evento central \u2192 posteriormente \u2192 finalmente",
      "Build and explain a complex timeline with earlier, central, and later events",
      ["Anteriormente hab\xEDa trabajado all\xED.", "Posteriormente, cambi\xF3 de puesto."],
      "Provide six events from two time layers out of order and ask for a coherent retelling with temporal framing",
      "The learner reconstructs the full timeline without confusing the earlier-past and main-past layers"
    ),
    "lesson-b2-2-2": agenda2(
      "B2",
      [
        "se fabrica...",
        "es fabricado por...",
        "fue creado para...",
        "se utiliza para...",
        "est\xE1 compuesto de...",
        "mediante...",
        "como resultado..."
      ],
      "materia prima \u2192 proceso \u2192 agente \u2192 uso \u2192 resultado",
      "Explain a process using impersonal, passive, and result-focused structures",
      ["Se fabrica con materiales reciclados.", "El sistema fue creado por un equipo internacional."],
      "Ask for five stages of a familiar production or technical process, varying who or what receives focus",
      "The learner uses at least two passive strategies and keeps agreement and process order accurate"
    ),
    "lesson-b2-2-3": agenda2(
      "B2",
      [
        "la empresa produce...",
        "se produce...",
        "fue aprobado por...",
        "se considera...",
        "est\xE1 terminado...",
        "se decidi\xF3 que...",
        "el informe fue..."
      ],
      "activa \u2192 pasiva \u2192 impersonal \u2192 justificaci\xF3n de registro",
      "Reformulate active statements into passive or impersonal language and justify the register choice",
      ["La empresa publica el informe. \u2192 El informe es publicado por la empresa."],
      "Give four active workplace or news statements and require two passive and two impersonal rewrites plus one style explanation",
      "The learner produces four accurate reformulations and explains one focus or register effect"
    ),
    "lesson-b2-3-2": agenda2(
      "B2",
      [
        "me dijo que...",
        "me pregunt\xF3 si...",
        "coment\xF3 que...",
        "a\xF1adi\xF3 que...",
        "pidi\xF3 que...",
        "seg\xFAn explic\xF3...",
        "neg\xF3 que..."
      ],
      "mensaje original \u2192 dijo / pregunt\xF3 / pidi\xF3 que... \u2192 fuente",
      "Retell a conversation while distinguishing statements, questions, and requests",
      ["Me pregunt\xF3 si pod\xEDa ir.", "Pidi\xF3 que envi\xE1ramos el documento."],
      "Present a six-line dialogue with two statements, two questions, and one request, then ask for a sourced retelling",
      "The learner reports each speech act with appropriate tense, pronoun, and reporting verb"
    ),
    "lesson-b2-3-3": agenda2(
      "B2",
      [
        "dijo que hab\xEDa...",
        "anunci\xF3 que har\xEDa...",
        "pregunt\xF3 d\xF3nde...",
        "neg\xF3 haber...",
        "aclar\xF3 que...",
        "al d\xEDa siguiente...",
        "aquel d\xEDa..."
      ],
      "cita \u2192 cambio de tiempo / persona / lugar \u2192 relato coherente",
      "Convert direct quotations into a coherent reported account with tense and reference shifts",
      ["\xABIr\xE9 ma\xF1ana\xBB. \u2192 Anunci\xF3 que ir\xEDa al d\xEDa siguiente."],
      "Supply five quotations containing past, future, person, place, and time references and require one continuous report",
      "The learner applies the required backshift and deixis changes without losing source meaning"
    ),
    "lesson-b2-4-2": agenda2(
      "B2",
      [
        "que...",
        "quien...",
        "donde...",
        "con quien...",
        "en el que...",
        "cuyo / cuya...",
        "lo que..."
      ],
      "dos ideas \u2192 relativo adecuado \u2192 una oraci\xF3n precisa",
      "Combine related statements using varied relative forms and explain the chosen connector",
      ["Conoc\xED a la autora. Su libro gan\xF3. \u2192 Conoc\xED a la autora cuyo libro gan\xF3."],
      "Give five statement pairs involving people, place, possession, and prepositions, then request combined versions",
      "The learner combines at least four pairs accurately and explains one relative-form choice"
    ),
    "lesson-b2-4-3": agenda2(
      "B2",
      [
        "el cual / la cual...",
        "lo que...",
        "cuyo / cuya...",
        "mediante el cual...",
        "..., que,...",
        "en el que...",
        "a quien..."
      ],
      "oraci\xF3n compleja \u2192 referente \u2192 informaci\xF3n esencial / adicional \u2192 par\xE1frasis",
      "Unpack complex relative clauses and reformulate them without losing reference or emphasis",
      ["El acuerdo, mediante el cual se resolvi\xF3 el conflicto, fue firmado ayer."],
      "Present four dense sentences, ask who or what each relative refers to, then require a clearer paraphrase",
      "The learner resolves every reference and preserves essential versus additional information",
      { kind: "comprehension", evidenceType: "analyze_and_reformulate" }
    ),
    "lesson-b2-5-2": agenda2(
      "B2",
      [
        "hola / estimado se\xF1or...",
        "\xBFpuedes...? / \xBFpodr\xEDa...?",
        "t\xFA / usted",
        "quiero... / le agradecer\xEDa que...",
        "gracias / un cordial saludo",
        "oye... / disculpe...",
        "te env\xEDo... / adjunto..."
      ],
      "mismo mensaje \u2192 versi\xF3n informal \u2192 versi\xF3n formal \u2192 cambios justificados",
      "Deliver the same request in informal and formal registers and explain the changes",
      ["\xBFPuedes envi\xE1rmelo? / \xBFPodr\xEDa envi\xE1rmelo, por favor?"],
      "Give one request scenario and two audiences, requiring complete openings, request wording, and closings for each",
      "The learner produces two coherent versions and identifies at least two register changes"
    ),
    "lesson-b2-5-3": agenda2(
      "B2",
      [
        "es adecuado para...",
        "resulta demasiado informal",
        "suena excesivamente formal",
        "en este contexto...",
        "convendr\xEDa...",
        "reformular\xEDa...",
        "ser\xEDa mejor decir..."
      ],
      "contexto + audiencia \u2192 evaluaci\xF3n de registro \u2192 reformulaci\xF3n",
      "Evaluate whether three messages fit their contexts and reformulate the weakest one",
      ["Resulta demasiado informal para una solicitud oficial.", "Ser\xEDa mejor decir..."],
      "Present a friend message, workplace request, and formal complaint with one mismatch, then require diagnosis and revision",
      "The learner evaluates all three registers and produces a context-appropriate reformulation",
      { kind: "comprehension", evidenceType: "evaluate_and_rewrite" }
    ),
    "lesson-b2-6-2": agenda2(
      "B2",
      [
        "el orden del d\xEDa...",
        "el objetivo es...",
        "seg\xFAn el informe...",
        "propongo que...",
        "estoy de acuerdo, pero...",
        "queda pendiente...",
        "el pr\xF3ximo paso es..."
      ],
      "objetivo \u2192 actualizaci\xF3n \u2192 propuesta \u2192 objeci\xF3n \u2192 decisi\xF3n \u2192 pr\xF3ximo paso",
      "Lead a focused meeting update from objective through decision and next step",
      ["Seg\xFAn el informe, las ventas aumentaron.", "Queda pendiente confirmar el plazo."],
      "Simulate a six-turn meeting with one update, proposal, concern, decision, responsibility, and next step",
      "The learner structures the meeting clearly and closes with an assigned or explicit next action"
    ),
    "lesson-b2-6-3": agenda2(
      "B2",
      [
        "nuestra propuesta es...",
        "las condiciones son...",
        "estar\xEDamos dispuestos a...",
        "siempre que...",
        "sin embargo...",
        "llegar a un acuerdo",
        "el plazo ser\xEDa..."
      ],
      "propuesta \u2192 condiciones \u2192 concesi\xF3n \u2192 contrapropuesta \u2192 acuerdo",
      "Negotiate a proposal through conditions, concession, and a documented agreement",
      ["Estar\xEDamos dispuestos a aceptar, siempre que cambie el plazo."],
      "Set two conflicting priorities and require an opening proposal, condition, concession, counterproposal, and close",
      "The learner protects a priority, makes a meaningful concession, and reaches a precise agreement"
    ),
    "lesson-b2-7-2": agenda2(
      "B2",
      [
        "consiste en...",
        "funciona mediante...",
        "se basa en...",
        "los datos muestran que...",
        "debido a...",
        "por lo tanto...",
        "permite..."
      ],
      "principio \u2192 mecanismo \u2192 datos \u2192 causa \u2192 resultado",
      "Explain how a technology works and connect evidence to its result",
      ["Funciona mediante sensores.", "Los datos muestran que reduce el consumo."],
      "Ask for the technology's purpose, mechanism, one data point, causal explanation, and practical result",
      "The learner gives a technically coherent explanation and links evidence to the stated result"
    ),
    "lesson-b2-7-3": agenda2(
      "B2",
      [
        "la evidencia indica que...",
        "podr\xEDa...",
        "es probable que...",
        "no est\xE1 demostrado que...",
        "seg\xFAn los datos...",
        "a largo plazo...",
        "una limitaci\xF3n es..."
      ],
      "evidencia \u2192 predicci\xF3n \u2192 l\xEDmite \u2192 efecto a largo plazo",
      "Distinguish evidence from speculation and defend a qualified technology prediction",
      ["Seg\xFAn los datos, ya mejora la precisi\xF3n.", "A largo plazo podr\xEDa..., aunque..."],
      "Provide two evidence statements and two speculative claims, requiring classification, prediction, and one limitation",
      "The learner grounds the prediction in evidence and explicitly qualifies uncertainty or limitation"
    ),
    "lesson-b2-8-2": agenda2(
      "B2",
      [
        "el problema afecta a...",
        "una causa es...",
        "la iniciativa busca...",
        "el objetivo principal...",
        "hasta ahora ha logrado...",
        "ser\xEDa necesario...",
        "para mejorar..."
      ],
      "problema \u2192 poblaci\xF3n afectada \u2192 iniciativa \u2192 resultado \u2192 mejora",
      "Assess a community initiative by its problem, goal, result, and needed improvement",
      ["La iniciativa busca reducir la desigualdad.", "Para mejorar, ser\xEDa necesario..."],
      "Present a short initiative profile and ask for affected group, cause, goal, result, and one recommendation",
      "The learner accurately summarizes the initiative and proposes a relevant improvement",
      { kind: "comprehension", evidenceType: "assess_and_recommend" }
    ),
    "lesson-b2-8-3": agenda2(
      "B2",
      [
        "sostengo que...",
        "la evidencia muestra...",
        "debido a...",
        "aunque...",
        "una posible objeci\xF3n es...",
        "responder\xEDa que...",
        "propongo que..."
      ],
      "tesis \u2192 evidencia \u2192 concesi\xF3n \u2192 objeci\xF3n \u2192 respuesta \u2192 propuesta",
      "Argue for social change using evidence and a response to one objection",
      ["Sostengo que debe cambiar porque...", "Una posible objeci\xF3n es...; responder\xEDa que..."],
      "Require a claim, supporting evidence, causal link, concession, tutor-supplied objection, response, and action",
      "The learner sustains the argument through evidence and addresses the objection directly"
    ),
    "lesson-b2-9-2": agenda2(
      "B2",
      [
        "se caracteriza por...",
        "surgi\xF3 en...",
        "su estilo...",
        "influy\xF3 en...",
        "mientras que...",
        "a diferencia de...",
        "ambos movimientos..."
      ],
      "origen \u2192 rasgo definitorio \u2192 influencia \u2192 semejanza \u2192 diferencia",
      "Compare two artistic movements through period, defining features, and influence",
      ["Ambos movimientos rompieron con la tradici\xF3n.", "A diferencia del primero..."],
      "Provide two concise movement profiles and ask for timeline, defining feature, influence, similarity, and contrast",
      "The learner compares both movements with accurate contextual and stylistic support",
      { kind: "comprehension", evidenceType: "compare_and_explain" }
    ),
    "lesson-b2-9-3": agenda2(
      "B2",
      [
        "la obra refleja...",
        "representa...",
        "en su contexto...",
        "los valores de...",
        "funciona como s\xEDmbolo de...",
        "se puede interpretar como...",
        "debido a..."
      ],
      "detalle de la obra \u2192 s\xEDmbolo \u2192 contexto \u2192 valor \u2192 interpretaci\xF3n",
      "Interpret how a work reflects cultural values and historical context",
      ["La figura funciona como s\xEDmbolo de libertad.", "En su contexto, representa..."],
      "Present a short work description with three observable details, requiring symbol, context, value, and interpretation",
      "The learner grounds the interpretation in at least two details rather than giving an unsupported opinion"
    ),
    "lesson-b2-10-2": agenda2(
      "B2",
      [
        "desde mi punto de vista...",
        "por un lado...",
        "por otro lado...",
        "si bien...",
        "sin embargo...",
        "seg\xFAn...",
        "no creo que..."
      ],
      "posici\xF3n \u2192 dos perspectivas \u2192 fuente \u2192 concesi\xF3n \u2192 conclusi\xF3n",
      "Present a balanced political view with source attribution and concession",
      ["Si bien la medida ayuda, tambi\xE9n tiene costos.", "Seg\xFAn el informe..."],
      "Ask for a position, the strongest point on each side, one source, a concession, and final judgment",
      "The learner represents both sides fairly before reaching a supported conclusion"
    ),
    "lesson-b2-10-3": agenda2(
      "B2",
      [
        "propongo que...",
        "beneficiar\xEDa a...",
        "se podr\xEDa...",
        "una preocupaci\xF3n es...",
        "para responder a eso...",
        "el primer paso ser\xEDa...",
        "los ciudadanos podr\xEDan..."
      ],
      "acci\xF3n \u2192 beneficio \u2192 preocupaci\xF3n \u2192 respuesta \u2192 primer paso",
      "Propose a civic action, explain its benefit, and answer one practical concern",
      ["Propongo que se ampl\xEDe el programa.", "Para responder a esa preocupaci\xF3n..."],
      "Use a local issue to require an action, beneficiaries, implementation method, concern, response, and first step",
      "The learner presents an actionable proposal and responds specifically to the concern"
    ),
    "lesson-b2-11-2": agenda2(
      "B2",
      [
        "seg\xFAn...",
        "convendr\xEDa...",
        "es importante que...",
        "deber\xEDas...",
        "adem\xE1s...",
        "en cambio...",
        "mantener un equilibrio"
      ],
      "situaci\xF3n \u2192 evidencia \u2192 dos recomendaciones \u2192 contraste \u2192 equilibrio",
      "Create a balanced health recommendation supported by the person's situation",
      ["Seg\xFAn tus h\xE1bitos, convendr\xEDa dormir m\xE1s.", "Adem\xE1s, es importante que..."],
      "Give a lifestyle profile with competing needs, asking for two recommendations, one contrast, and a balanced priority",
      "The learner tailors the advice to the evidence and avoids a one-dimensional solution"
    ),
    "lesson-b2-11-3": agenda2(
      "B2",
      [
        "influye en...",
        "est\xE1 relacionado con...",
        "si..., entonces...",
        "tanto... como...",
        "a corto plazo...",
        "a largo plazo...",
        "el plan incluir\xEDa..."
      ],
      "factores conectados \u2192 efecto inmediato \u2192 efecto futuro \u2192 plan integrado",
      "Explain how four wellbeing factors interact and propose an integrated plan",
      ["El sue\xF1o influye en el estr\xE9s.", "El plan incluir\xEDa tanto descanso como ejercicio."],
      "Require links among sleep, nutrition, movement, and stress, then a short- and long-term plan",
      "The learner explains at least three relationships and proposes a plan addressing all four factors"
    ),
    "lesson-b2-12-2": agenda2(
      "B2",
      [
        "lo importante es...",
        "significa...",
        "desde esta perspectiva...",
        "depende de...",
        "se puede considerar...",
        "por ejemplo...",
        "en cambio..."
      ],
      "concepto \u2192 definici\xF3n \u2192 ejemplo \u2192 perspectiva alternativa \u2192 matiz",
      "Define an abstract concept and examine it from two perspectives",
      ["La libertad significa...", "Desde otra perspectiva, depende de..."],
      "Choose one abstract concept, require a definition, example, alternate perspective, and qualified conclusion",
      "The learner develops the concept beyond a personal preference and acknowledges a meaningful alternative"
    ),
    "lesson-b2-12-3": agenda2(
      "B2",
      [
        "en otras palabras...",
        "el autor sostiene que...",
        "se refiere a...",
        "sin embargo...",
        "esto implica que...",
        "desde mi punto de vista...",
        "matizar\xEDa que..."
      ],
      "tesis ajena \u2192 par\xE1frasis \u2192 implicaci\xF3n \u2192 objeci\xF3n \u2192 postura matizada",
      "Paraphrase a philosophical claim, explain its implication, and offer a nuanced response",
      ["En otras palabras, el autor sostiene que...", "Matizar\xEDa esa idea porque..."],
      "Present a short philosophical passage, ask for plain-language paraphrase, implication, limitation, and response",
      "The learner preserves the original claim while adding a distinct, qualified evaluation",
      { kind: "comprehension", evidenceType: "paraphrase_and_evaluate" }
    )
  });
  var buildAgenda2 = (lessonId, spec, modes) => [
    ...spec.forms.map((form, index) => formItem2(lessonId, index, form, modes)),
    applicationItem2(lessonId, spec.application, modes, spec.forms)
  ];
  function getManualB1B2AgendaItems(lesson, { modes = null } = {}) {
    const lessonId = typeof lesson === "string" ? lesson : lesson?.id;
    const spec = MANUAL_B1_B2_AGENDAS[lessonId];
    if (!spec) return [];
    const lessonModes = modes || (typeof lesson === "object" && Array.isArray(lesson?.modes) ? lesson.modes : ["vocabulary", "realtime"]);
    return buildAgenda2(lessonId, spec, lessonModes);
  }
  function getManualB1B2FoundationFormItems(lesson, { modes = ["vocabulary"] } = {}) {
    const lessonId = typeof lesson === "string" ? lesson : lesson?.id;
    const forms = B1_B2_FOUNDATION_FORMS[lessonId];
    if (!forms) return [];
    return forms.map((form, index) => formItem2(lessonId, index, form, modes));
  }

  // ../nosabos/nosabos/src/data/manualC1C2Agendas.js
  var FORM_LABEL_PREFIXES3 = Object.freeze({
    en: "Use precisely in context",
    es: "Usa con precisi\xF3n en contexto",
    pt: "Use com precis\xE3o em contexto",
    it: "Usa con precisione nel contesto",
    fr: "Utilise avec pr\xE9cision en contexte",
    de: "Pr\xE4zise im Kontext verwenden",
    ja: "\u6587\u8108\u306B\u5FDC\u3058\u3066\u6B63\u78BA\u306B\u4F7F\u3046",
    hi: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0938\u091F\u0940\u0915 \u0930\u0942\u092A \u0938\u0947 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
    ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0628\u062F\u0642\u0629 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
    zh: "\u5728\u8BED\u5883\u4E2D\u51C6\u786E\u4F7F\u7528"
  });
  var APPLICATION_LABEL_PREFIXES2 = Object.freeze({
    C1: {
      en: "Deliver the structured response",
      es: "Desarrolla la respuesta estructurada",
      pt: "Desenvolva a resposta estruturada",
      it: "Sviluppa la risposta strutturata",
      fr: "D\xE9veloppe la r\xE9ponse structur\xE9e",
      de: "Die strukturierte Antwort ausf\xFChren",
      ja: "\u69CB\u6210\u306E\u6574\u3063\u305F\u5FDC\u7B54\u3092\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u0938\u0902\u0930\u091A\u093F\u0924 \u0909\u0924\u094D\u0924\u0930 \u092A\u094D\u0930\u0938\u094D\u0924\u0941\u0924 \u0915\u0930\u0947\u0902",
      ar: "\u0642\u062F\u0651\u0645 \u0627\u0644\u0627\u0633\u062A\u062C\u0627\u0628\u0629 \u0627\u0644\u0645\u0646\u0638\u0645\u0629",
      zh: "\u5B8C\u6210\u7ED3\u6784\u6E05\u6670\u7684\u56DE\u7B54"
    },
    C2: {
      en: "Craft and adapt the precise response",
      es: "Elabora y adapta la respuesta precisa",
      pt: "Elabore e adapte a resposta precisa",
      it: "Elabora e adatta la risposta precisa",
      fr: "\xC9labore et adapte la r\xE9ponse pr\xE9cise",
      de: "Die pr\xE4zise Antwort ausarbeiten und anpassen",
      ja: "\u7CBE\u5BC6\u306A\u5FDC\u7B54\u3092\u7DF4\u308A\u3001\u6587\u8108\u306B\u5408\u308F\u305B\u308B",
      hi: "\u0938\u091F\u0940\u0915 \u0909\u0924\u094D\u0924\u0930 \u0924\u0948\u092F\u093E\u0930 \u0915\u0930\u0947\u0902 \u0914\u0930 \u0909\u0938\u0947 \u0905\u0928\u0941\u0915\u0942\u0932\u093F\u0924 \u0915\u0930\u0947\u0902",
      ar: "\u0635\u064F\u063A \u0627\u0644\u0627\u0633\u062A\u062C\u0627\u0628\u0629 \u0627\u0644\u062F\u0642\u064A\u0642\u0629 \u0648\u0643\u064A\u0651\u0641\u0647\u0627",
      zh: "\u7EC4\u7EC7\u5E76\u8C03\u6574\u7CBE\u51C6\u7684\u56DE\u7B54"
    }
  });
  var formItem3 = (lessonId, index, form, modes) => ({
    id: `manual-${lessonId}-form-${index + 1}`,
    kind: "vocabulary",
    modes,
    label: Object.fromEntries(
      Object.entries(FORM_LABEL_PREFIXES3).map(([lang, prefix]) => [
        lang,
        `${prefix}: ${form}`
      ])
    ),
    goal: `Interpret and produce "${form}" with its intended stance or register`,
    targetConcept: form,
    targetRole: "form",
    targetForms: [form],
    targetExamples: [form],
    activityBrief: "Establish the phrase's meaning, stance, register, and discourse function; contrast it with a nearby alternative; then elicit an original use",
    evidence: {
      type: "produce_with_precision",
      criteria: `The learner uses "${form}" accurately with an appropriate stance and register`
    },
    source: "manual-c1-c2-agenda",
    spanishOnly: true
  });
  var applicationItem3 = (lessonId, spec, modes, forms) => ({
    id: `manual-${lessonId}-application`,
    kind: spec.kind || "communication",
    modes,
    label: Object.fromEntries(
      Object.entries(APPLICATION_LABEL_PREFIXES2[spec.level]).map(
        ([lang, prefix]) => [
          lang,
          `${prefix}: ${forms.slice(0, 5).join(" \u2192 ")}`
        ]
      )
    ),
    goal: spec.goal,
    targetConcept: spec.goal,
    targetRole: "goal",
    targetForms: [],
    targetExamples: spec.examples,
    activityBrief: spec.activityBrief,
    evidence: {
      type: spec.evidenceType || "extended_response",
      criteria: spec.evidence
    },
    source: "manual-c1-c2-agenda",
    spanishOnly: true
  });
  var agenda3 = (level, forms, goal, examples, activityBrief, evidence, options = {}) => ({
    forms,
    application: {
      level,
      goal,
      examples,
      activityBrief,
      evidence,
      ...options
    }
  });
  var C1_C2_FOUNDATION_FORMS = Object.freeze({
    "lesson-c1-1-1": [
      "quiero que...",
      "espero que...",
      "dudo que...",
      "me alegra que...",
      "es importante que...",
      "cuando + subjuntivo",
      "para que...",
      "a menos que..."
    ],
    "lesson-c1-2-1": [
      "quer\xEDa que...",
      "esperaba que...",
      "dudaba que...",
      "ojal\xE1 pudiera...",
      "como si fuera...",
      "hablara / hablase",
      "hubiera + participio",
      "de haberlo sabido..."
    ],
    "lesson-c1-3-1": [
      "si tengo..., har\xE9...",
      "si tuviera..., har\xEDa...",
      "si hubiera tenido..., habr\xEDa...",
      "a menos que...",
      "en caso de que...",
      "siempre que...",
      "con tal de que...",
      "de + infinitivo"
    ],
    "lesson-c1-4-1": [
      "echar de menos",
      "darse cuenta de",
      "valer la pena",
      "tener ganas de",
      "ponerse las pilas",
      "hacerse el / la tonto/a",
      "dar la lata",
      "dar igual"
    ],
    "lesson-c1-5-1": [
      "plantear una tesis",
      "sostener que...",
      "los datos indican que...",
      "cabe se\xF1alar que...",
      "por consiguiente...",
      "no obstante...",
      "en cuanto a...",
      "se concluye que..."
    ],
    "lesson-c1-6-1": [
      "le agradecer\xEDa que...",
      "quedo a la espera de...",
      "adjunto / adjunta...",
      "respecto a...",
      "seg\xFAn lo acordado...",
      "convendr\xEDa...",
      "propongo que...",
      "un cordial saludo"
    ],
    "lesson-c1-7-1": [
      "sostengo que...",
      "considero que...",
      "estoy a favor de...",
      "estoy en contra de...",
      "si bien...",
      "aunque...",
      "por un lado... por otro...",
      "no creo que..."
    ],
    "lesson-c1-8-1": [
      "los valores",
      "las costumbres",
      "la identidad",
      "la tradici\xF3n",
      "la modernidad",
      "el estereotipo",
      "la diversidad",
      "suele / tiende a..."
    ],
    "lesson-c1-9-1": [
      "el narrador / la narradora",
      "la focalizaci\xF3n",
      "la met\xE1fora",
      "el s\xEDmbolo",
      "el tono",
      "la imagen",
      "el ritmo",
      "la iron\xEDa"
    ],
    "lesson-c1-10-1": [
      "en primer lugar...",
      "a continuaci\xF3n...",
      "ahora bien...",
      "por lo tanto...",
      "en cambio...",
      "respecto a...",
      "dicho esto...",
      "en definitiva..."
    ],
    "lesson-c2-1-1": [
      "meter la pata",
      "costar un ojo de la cara",
      "estar en las nubes",
      "echar una mano",
      "no tener pelos en la lengua",
      "tomar el pelo",
      "ser pan comido",
      "estar pez"
    ],
    "lesson-c2-2-1": [
      "el carro / el coche / el auto",
      "la computadora / el ordenador",
      "el celular / el m\xF3vil",
      "el jugo / el zumo",
      "la papa / la patata",
      "t\xFA tienes / vos ten\xE9s / usted tiene",
      "vosotros habl\xE1is / ustedes hablan",
      "vos habl\xE1s / com\xE9s / viv\xEDs"
    ],
    "lesson-c2-3-1": [
      "solicitar / pedir",
      "adquirir / conseguir",
      "comenzar / empezar",
      "no obstante / pero",
      "cabe destacar que...",
      "dicho esto...",
      "por ende...",
      "se + verbo impersonal"
    ],
    "lesson-c2-4-1": [
      "la met\xE1fora",
      "el s\xEDmil",
      "la hip\xE9rbole",
      "la iron\xEDa",
      "la personificaci\xF3n",
      "la an\xE1fora",
      "la pregunta ret\xF3rica",
      "la ant\xEDtesis"
    ],
    "lesson-c2-5-1": [
      "se entiende por...",
      "en virtud de...",
      "presenta s\xEDntomas de...",
      "el diagn\xF3stico indica...",
      "seg\xFAn el presupuesto...",
      "la inversi\xF3n supone...",
      "en t\xE9rminos t\xE9cnicos...",
      "en lenguaje llano..."
    ],
    "lesson-c2-6-1": [
      "delgado / flaco / esquel\xE9tico",
      "barato / econ\xF3mico / cutre",
      "bonito / lindo / hermoso",
      "sugerir / insistir / exigir",
      "ser / estar",
      "por / para",
      "indicativo / subjuntivo",
      "literal / ir\xF3nico"
    ],
    "lesson-c2-7-1": [
      "A mal tiempo, buena cara",
      "M\xE1s vale tarde que nunca",
      "Buen provecho / Que aproveche",
      "Lo siento mucho",
      "Mi m\xE1s sentido p\xE9same",
      "\xA1Salud!",
      "brindemos por...",
      "\xBFnos tuteamos?"
    ],
    "lesson-c2-8-1": [
      "o sea...",
      "pues...",
      "es que...",
      "a ver...",
      "total, que...",
      "resulta que...",
      "digo / quiero decir...",
      "mejor dicho..."
    ]
  });
  var MANUAL_C1_C2_AGENDAS = Object.freeze({
    "lesson-c1-1-2": agenda3(
      "C1",
      [
        "espero que...",
        "ojal\xE1...",
        "me alegra que...",
        "lamento que...",
        "es posible que...",
        "no creo que...",
        "conviene que..."
      ],
      "Express hopes, emotional reactions, reservations, and advice about a friend's plans",
      ["Espero que te vaya bien", "No creo que sea f\xE1cil, pero conviene que lo intentes"],
      "Present three decisions a friend is considering; elicit a connected response containing a hope, reaction, reservation, and recommendation",
      "The learner uses at least five target frames, maintains subjunctive control, and distinguishes emotion, possibility, doubt, and advice"
    ),
    "lesson-c1-1-3": agenda3(
      "C1",
      [
        "aunque es...",
        "aunque sea...",
        "cuando tenga...",
        "para que...",
        "sin que...",
        "a menos que...",
        "siempre que..."
      ],
      "Negotiate a plan while choosing mood to distinguish facts, possibilities, purposes, and conditions",
      ["Aunque es caro, iremos", "Aunque sea caro, iremos", "Iremos cuando tengamos tiempo"],
      "Negotiate a shared plan with one known obstacle and two uncertain conditions; require the learner to explain each indicative or subjunctive choice",
      "The learner completes the plan with at least five frames and explains how mood changes certainty or communicative intent"
    ),
    "lesson-c1-2-2": agenda3(
      "C1",
      [
        "quisiera...",
        "me gustar\xEDa que...",
        "\xBFser\xEDa posible que...?",
        "preferir\xEDa que...",
        "le agradecer\xEDa que...",
        "ojal\xE1 pudiera...",
        "si no fuera mucha molestia..."
      ],
      "Make and negotiate delicate requests with an appropriate degree of distance and politeness",
      ["Quisiera cambiar la fecha", "Si no fuera mucha molestia, le agradecer\xEDa que lo revisara"],
      "Role-play requesting three changes from a landlord, professor, or manager; vary urgency, power distance, and degree of imposition",
      "The learner uses at least five softening frames and adjusts formality without making the request unclear"
    ),
    "lesson-c1-2-3": agenda3(
      "C1",
      [
        "ojal\xE1 hubiera...",
        "si hubiera..., habr\xEDa...",
        "me arrepiento de haber...",
        "lament\xE9 que...",
        "como si nada hubiera pasado...",
        "de haber sabido...",
        "habr\xEDa preferido que..."
      ],
      "Reflect on an unreal past by connecting regret, consequence, and an alternative course of action",
      ["De haberlo sabido, habr\xEDa actuado de otra manera", "Ojal\xE1 hubiera pedido ayuda"],
      "Give the learner a consequential past decision; elicit what happened, what they regret, an unreal alternative, and its likely result",
      "The learner produces a coherent reflection with at least five frames and keeps past time relationships clear"
    ),
    "lesson-c1-3-2": agenda3(
      "C1",
      [
        "si pudiera...",
        "si tuviera...",
        "de ser as\xED...",
        "en caso de que...",
        "siempre que...",
        "a condici\xF3n de que...",
        "salvo que..."
      ],
      "Evaluate a difficult proposal by setting hypothetical conditions, safeguards, and exceptions",
      ["De ser as\xED, lo aceptar\xEDa", "Estar\xEDa de acuerdo siempre que hubiera garant\xEDas"],
      "Present a proposal with benefits and risks; require acceptance, rejection, or revision under at least three explicit conditions",
      "The learner uses at least five conditional frames and makes the relationship between condition and consequence unambiguous"
    ),
    "lesson-c1-3-3": agenda3(
      "C1",
      [
        "si hubiera..., habr\xEDa...",
        "de haber...",
        "si no fuera por...",
        "aun si...",
        "suponiendo que...",
        "siempre y cuando...",
        "en el supuesto de que..."
      ],
      "Reason across past and present time frames to explain how one changed condition would affect an outcome",
      ["Si hubiera aceptado, ahora estar\xEDa all\xED", "Aun si lo hubi\xE9ramos sabido, no habr\xEDa cambiado nada"],
      "Analyze a past decision with a present consequence, test two counterfactual alternatives, and defend the most plausible one",
      "The learner produces at least three logically consistent condition\u2013result chains using five or more target frames"
    ),
    "lesson-c1-4-2": agenda3(
      "C1",
      [
        "echar de menos",
        "tener ganas de",
        "darse cuenta de",
        "ponerse las pilas",
        "dar igual",
        "tomar el pelo",
        "no tener pelos en la lengua"
      ],
      "Use idioms naturally in an informal conversation without forcing or misregistering them",
      ["Me di cuenta de que me estaba tomando el pelo", "Tendremos que ponernos las pilas"],
      "Role-play catching up with a friend about work, relationships, and plans; introduce contexts that naturally license the idioms",
      "The learner uses at least five idioms with the intended meaning and keeps the overall conversation natural"
    ),
    "lesson-c1-4-3": agenda3(
      "C1",
      [
        "no dar pie con bola",
        "quedarse de piedra",
        "estar entre la espada y la pared",
        "ir al grano",
        "salir por la tangente",
        "ser la gota que colma el vaso",
        "dar en el clavo"
      ],
      "Infer unfamiliar idioms from context and use them to retell a conflict with precise figurative meaning",
      ["Me qued\xE9 de piedra", "Su respuesta fue la gota que colm\xF3 el vaso"],
      "Present a short conflict containing four idioms, ask the learner to infer them, then retell and resolve the conflict using five target idioms",
      "The learner explains the figurative meanings and uses at least five idioms consistently in the retelling",
      { kind: "comprehension", evidenceType: "infer_and_reproduce" }
    ),
    "lesson-c1-5-2": agenda3(
      "C1",
      [
        "sostengo que...",
        "la evidencia muestra que...",
        "seg\xFAn...",
        "esto se debe a...",
        "sin embargo...",
        "una limitaci\xF3n es...",
        "por lo tanto..."
      ],
      "Defend an academic claim with evidence, causal reasoning, a limitation, and a qualified conclusion",
      ["La evidencia muestra que...", "Sin embargo, una limitaci\xF3n es..."],
      "Provide a research question and two short findings; elicit a thesis defense that cites both findings and acknowledges one limitation",
      "The learner develops a traceable claim\u2013evidence\u2013reasoning chain with at least five target frames"
    ),
    "lesson-c1-5-3": agenda3(
      "C1",
      [
        "el autor sostiene que...",
        "se basa en...",
        "presupone que...",
        "no distingue entre...",
        "en cambio...",
        "puede interpretarse como...",
        "en s\xEDntesis..."
      ],
      "Analyze and paraphrase a dense argument while separating its claim, assumptions, evidence, and limitations",
      ["El autor sostiene que...", "El argumento presupone que..."],
      "Present a short abstract; ask for a plain-language paraphrase, one hidden assumption, one limitation, and an objective synthesis",
      "The learner preserves the source claim, identifies a defensible assumption or limitation, and uses at least five frames",
      { kind: "comprehension", evidenceType: "paraphrase_and_evaluate" }
    ),
    "lesson-c1-6-2": agenda3(
      "C1",
      [
        "\xBFser\xEDa posible...?",
        "debido a...",
        "propongo reprogramar...",
        "\xBFle vendr\xEDa bien...?",
        "confirmo que...",
        "quedo pendiente de...",
        "disculpe las molestias..."
      ],
      "Reschedule a professional commitment while explaining the constraint, offering options, and confirming next steps",
      ["Debido a un imprevisto, propongo reprogramar la reuni\xF3n", "\xBFLe vendr\xEDa bien el jueves?"],
      "Role-play a call or exchange in which the learner must reschedule, offer two viable alternatives, respond to a constraint, and confirm",
      "The learner completes the rescheduling with at least five frames, appropriate formality, and a mutually clear outcome"
    ),
    "lesson-c1-6-3": agenda3(
      "C1",
      [
        "nuestro objetivo es...",
        "propongo que...",
        "\xBFqu\xE9 opinan?",
        "entiendo su preocupaci\xF3n...",
        "para resumir...",
        "quedamos en que...",
        "el siguiente paso ser\xE1..."
      ],
      "Lead a concise planning meeting by framing the goal, eliciting views, resolving a concern, and assigning next steps",
      ["Nuestro objetivo es acordar prioridades", "Quedamos en que el siguiente paso ser\xE1..."],
      "Simulate a meeting with competing priorities; require an opening, input invitation, response to disagreement, summary, and action assignment",
      "The learner leads all five meeting stages and uses at least five frames with clear ownership and deadlines"
    ),
    "lesson-c1-7-2": agenda3(
      "C1",
      [
        "mi tesis es que...",
        "la evidencia principal es...",
        "por ejemplo...",
        "esto demuestra que...",
        "concedo que...",
        "sin embargo...",
        "por lo tanto..."
      ],
      "Build a persuasive argument with a thesis, relevant evidence, explanation, concession, and conclusion",
      ["Mi tesis es que...", "Concedo que existe un riesgo; sin embargo..."],
      "Give a debatable claim and three evidence cards of unequal strength; require the learner to select, explain, concede, and conclude",
      "The learner constructs a coherent argument, uses evidence rather than assertion, and deploys at least five frames"
    ),
    "lesson-c1-7-3": agenda3(
      "C1",
      [
        "entiendo el argumento de que...",
        "si bien...",
        "no obstante...",
        "esa conclusi\xF3n presupone que...",
        "los datos no demuestran que...",
        "una explicaci\xF3n alternativa es...",
        "por eso mantengo que..."
      ],
      "Rebut an opposing position fairly by conceding its strongest point and challenging its evidence or assumption",
      ["Si bien el argumento es v\xE1lido en parte...", "Una explicaci\xF3n alternativa es..."],
      "Present a strong opposing argument; require a fair summary, concession, critique of one assumption or inference, alternative explanation, and position",
      "The learner avoids distortion, addresses the argument's logic, and uses at least five rebuttal frames"
    ),
    "lesson-c1-8-2": agenda3(
      "C1",
      [
        "se suele...",
        "tiende a...",
        "a diferencia de...",
        "mientras que...",
        "esto refleja...",
        "desde esta perspectiva...",
        "no se puede generalizar..."
      ],
      "Compare two cultural practices while interpreting values and explicitly limiting generalizations",
      ["A diferencia de..., se suele...", "Esto refleja..., aunque no se puede generalizar"],
      "Provide two accounts of a social practice; ask for similarities, differences, possible values, and a caution against stereotyping",
      "The learner makes a supported comparison using at least five frames and distinguishes observations from generalizations"
    ),
    "lesson-c1-8-3": agenda3(
      "C1",
      [
        "el texto da por sentado que...",
        "refleja la perspectiva de...",
        "omite...",
        "puede interpretarse como...",
        "conviene distinguir entre...",
        "no todas las personas...",
        "en su contexto..."
      ],
      "Identify cultural assumptions in a text and offer a contextualized interpretation without essentializing a group",
      ["El texto da por sentado que...", "Conviene distinguir entre la pr\xE1ctica y el estereotipo"],
      "Present a short culturally situated article; require an assumption, omitted perspective, contextual factor, and revised interpretation",
      "The learner supports each inference from the text and uses at least five frames without treating a group as uniform",
      { kind: "comprehension", evidenceType: "critical_interpretation" }
    ),
    "lesson-c1-9-2": agenda3(
      "C1",
      [
        "el narrador sugiere que...",
        "la imagen evoca...",
        "el tono pasa de... a...",
        "el s\xEDmbolo representa...",
        "la met\xE1fora refuerza...",
        "el contraste entre... y...",
        "el ritmo crea..."
      ],
      "Interpret a literary passage by linking specific stylistic choices to meaning and reader effect",
      ["La imagen evoca...", "El contraste refuerza la sensaci\xF3n de..."],
      "Present a short passage; ask the learner to identify three devices, cite their textual basis, and explain their combined effect",
      "The learner makes at least three evidence-based interpretations and uses five or more analytical frames",
      { kind: "comprehension", evidenceType: "textual_analysis" }
    ),
    "lesson-c1-9-3": agenda3(
      "C1",
      [
        "a diferencia de...",
        "mientras que...",
        "ambos textos...",
        "en el primer texto...",
        "en el segundo...",
        "esta elecci\xF3n produce...",
        "en conjunto..."
      ],
      "Compare two authors' styles and defend which choices create the stronger effect",
      ["Ambos textos tratan..., mientras que...", "Esta elecci\xF3n produce un efecto m\xE1s..."],
      "Provide two short treatments of the same event; require comparison of voice, imagery, rhythm, and effect with a justified judgment",
      "The learner supports the comparison with details from both texts and uses at least five frames",
      { kind: "comprehension", evidenceType: "comparative_analysis" }
    ),
    "lesson-c1-10-2": agenda3(
      "C1",
      [
        "para empezar...",
        "el punto central es...",
        "por una parte...",
        "ahora bien...",
        "esto se debe a...",
        "por consiguiente...",
        "en definitiva..."
      ],
      "Deliver a structured extended opinion whose progression remains clear from thesis through qualification to conclusion",
      ["El punto central es...", "Ahora bien, conviene considerar..."],
      "Ask for a two-minute response to a complex question with an opening thesis, two linked reasons, one qualification, and conclusion",
      "The learner sustains a traceable structure, uses at least five markers accurately, and avoids list-like disconnected speech"
    ),
    "lesson-c1-10-3": agenda3(
      "C1",
      [
        "en s\xEDntesis...",
        "en otras palabras...",
        "respecto a...",
        "dicho esto...",
        "conviene matizar que...",
        "de ah\xED que...",
        "en \xFAltima instancia..."
      ],
      "Synthesize a complex discussion, reformulate its key point, and preserve an important qualification",
      ["En otras palabras...", "Conviene matizar que..."],
      "Present two related positions and one exception; require a concise synthesis for an audience that has not heard the discussion",
      "The learner accurately combines both positions, retains the exception, and uses at least five cohesive frames",
      { kind: "mediation", evidenceType: "synthesize_and_reframe" }
    ),
    "lesson-c2-1-2": agenda3(
      "C2",
      [
        "no tener pelos en la lengua",
        "tomar el pelo",
        "estar hecho polvo",
        "ni de broma",
        "\xA1qu\xE9 va!",
        "me da igual",
        "a fin de cuentas..."
      ],
      "Sustain an idiomatic informal exchange while interpreting figurative intent and avoiding register clashes",
      ["\xA1Qu\xE9 va, ni de broma!", "A fin de cuentas, me da igual"],
      "Role-play a fast informal exchange involving teasing, refusal, fatigue, and a blunt opinion; ask for one later formal paraphrase",
      "The learner uses at least five idiomatic expressions naturally and accurately reformulates their meaning in neutral Spanish"
    ),
    "lesson-c2-1-3": agenda3(
      "C2",
      [
        "salirse con la suya",
        "andar con pies de plomo",
        "no tener ni pies ni cabeza",
        "dar en el clavo",
        "tirar la casa por la ventana",
        "estar en el ajo",
        "poner el dedo en la llaga"
      ],
      "Infer, explain, and redeploy unfamiliar idioms while preserving their connotation and conversational force",
      ["Hay que andar con pies de plomo", "Has puesto el dedo en la llaga"],
      "Embed five idioms in a story with sufficient contextual clues; require inference, neutral paraphrase, and a new story using the expressions",
      "The learner infers at least four meanings and uses five idioms with the intended connotation in a new context",
      { kind: "comprehension", evidenceType: "infer_paraphrase_and_transfer" }
    ),
    "lesson-c2-2-2": agenda3(
      "C2",
      [
        "vos ten\xE9s / t\xFA tienes",
        "ven\xED / ven",
        "decime / dime",
        "vosotros habl\xE1is / ustedes hablan",
        "\xBFqu\xE9 tal? / \xBFqu\xE9 onda?",
        "vale / \xF3rale / dale",
        "calle: /ka\u029De/ / /ka\u0283e/"
      ],
      "Adapt pronouns, imperatives, vocabulary, and expected pronunciation across three regional interlocutors",
      ["Vos ten\xE9s raz\xF3n; decime qu\xE9 pas\xF3", "Vale, decidme cu\xE1ndo lleg\xE1is"],
      "Simulate exchanges with speakers from the River Plate, Mexico, and Spain; require appropriate recognition and controlled adaptation without caricature",
      "The learner recognizes all seven contrasts and consistently adapts at least five regional choices to the interlocutor"
    ),
    "lesson-c2-2-3": agenda3(
      "C2",
      [
        "vos",
        "t\xFA",
        "usted",
        "vosotros / vosotras",
        "ustedes",
        "computadora / ordenador",
        "carro / coche / auto"
      ],
      "Compare regional systems and choose an appropriate variety and register for each audience",
      ["Con un colega peninsular usar\xEDa...", "En el R\xEDo de la Plata es habitual..."],
      "Present messages from three regions and three relationships; require identification, explanation, and audience-appropriate reformulation",
      "The learner correctly attributes the main regional cues and adapts each message without treating one variety as the default",
      { kind: "mediation", evidenceType: "identify_explain_and_adapt" }
    ),
    "lesson-c2-3-2": agenda3(
      "C2",
      [
        "\xBFme pasas...?",
        "\xBFme har\xEDas el favor de...?",
        "le agradecer\xEDa que...",
        "ser\xEDa conveniente...",
        "cabe se\xF1alar que...",
        "dicho sea de paso...",
        "no obstante..."
      ],
      "Transform the same message across intimate, neutral, professional, and formal registers without changing its core intent",
      ["\xBFMe pasas el documento?", "Le agradecer\xEDa que me remitiera el documento"],
      "Give one request, one disagreement, and one correction; require four audience-specific versions and an explanation of the linguistic changes",
      "The learner produces clearly differentiated registers and explains at least three lexical or grammatical choices"
    ),
    "lesson-c2-3-3": agenda3(
      "C2",
      [
        "como si...",
        "se dir\xEDa que...",
        "convertido / convertida en...",
        "lejos de...",
        "apenas...",
        "no solo... sino...",
        "y, sin embargo..."
      ],
      "Transform a literal description into expressive prose while controlling imagery, rhythm, and restraint",
      ["La ciudad despert\xF3 como si...", "Lejos de callarse, el viento..."],
      "Start with a plain description; require two stylistic versions for different moods, followed by a concise explanation of the effects created",
      "The learner uses at least five frames, creates internally consistent imagery, and can justify the stylistic choices"
    ),
    "lesson-c2-4-2": agenda3(
      "C2",
      [
        "\xBFhasta cu\xE1ndo...?",
        "no se trata de... sino de...",
        "imaginemos por un momento...",
        "todos sabemos que...",
        "si no actuamos...",
        "hoy...; ma\xF1ana...",
        "por eso les propongo..."
      ],
      "Craft a persuasive speech using rhetorical devices strategically rather than decoratively",
      ["No se trata de elegir entre..., sino de...", "\xBFHasta cu\xE1ndo aceptaremos...?"],
      "Assign a public issue and audience; require a hook, contrast, image, objection, and call to action in a short speech",
      "The learner uses at least five frames, matches devices to persuasive purpose, and maintains a coherent argument"
    ),
    "lesson-c2-4-3": agenda3(
      "C2",
      [
        "el autor apela a...",
        "la repetici\xF3n enfatiza...",
        "la met\xE1fora presenta... como...",
        "esta formulaci\xF3n oculta...",
        "el efecto buscado es...",
        "resulta persuasivo porque...",
        "sin embargo, pierde fuerza cuando..."
      ],
      "Evaluate how rhetoric shapes an audience while separating persuasive effect from argumentative validity",
      ["La met\xE1fora presenta el problema como...", "Resulta persuasivo; sin embargo..."],
      "Present a short persuasive passage; require device identification, audience effect, hidden assumption, validity judgment, and revised wording",
      "The learner supports the analysis from the text, distinguishes effect from evidence, and uses at least five frames",
      { kind: "comprehension", evidenceType: "rhetorical_evaluation" }
    ),
    "lesson-c2-5-2": agenda3(
      "C2",
      [
        "de conformidad con...",
        "queda sujeto a...",
        "presenta indicios de...",
        "se recomienda realizar...",
        "la partida presupuestaria...",
        "el rendimiento de la inversi\xF3n...",
        "los resultados son compatibles con..."
      ],
      "Use specialized collocations accurately while keeping legal, medical, and financial claims appropriately qualified",
      ["Queda sujeto a las condiciones...", "Los resultados son compatibles con, pero no confirman..."],
      "Provide three short professional cases; require a precise summary of each and correction of deliberately overconfident wording",
      "The learner uses at least five collocations accurately and does not overstate obligation, diagnosis, or certainty"
    ),
    "lesson-c2-5-3": agenda3(
      "C2",
      [
        "en t\xE9rminos t\xE9cnicos...",
        "dicho de forma sencilla...",
        "esto significa que...",
        "no implica necesariamente que...",
        "la consecuencia pr\xE1ctica es...",
        "para un p\xFAblico no especializado...",
        "sin perder precisi\xF3n..."
      ],
      "Mediate a specialized text for an expert and a lay audience without distorting its certainty or practical implications",
      ["Dicho de forma sencilla, esto significa que...", "No implica necesariamente que..."],
      "Give a dense excerpt; require an expert summary, a plain-language explanation, one practical consequence, and one limitation",
      "Both versions preserve the source's meaning and certainty while using audience-appropriate terminology and five target frames",
      { kind: "mediation", evidenceType: "dual_audience_mediation" }
    ),
    "lesson-c2-6-2": agenda3(
      "C2",
      [
        "no es lo mismo... que...",
        "sugiere que...",
        "implica que...",
        "da a entender que...",
        "m\xE1s bien...",
        "hasta cierto punto...",
        "apenas..."
      ],
      "Distinguish fine shades of meaning and explain how a lexical or grammatical choice alters the implied stance",
      ["No lo afirma; m\xE1s bien, da a entender que...", "Es v\xE1lido hasta cierto punto"],
      "Present near-equivalent statements with different connotations; require ranking, interpretation, and context-appropriate selection",
      "The learner explains at least four meaningful distinctions and uses five or more frames without flattening them into synonyms"
    ),
    "lesson-c2-6-3": agenda3(
      "C2",
      [
        "no es que...",
        "dicho sea con reservas...",
        "sin \xE1nimo de...",
        "me temo que...",
        "quiz\xE1 convendr\xEDa...",
        "curiosamente...",
        "con cierta iron\xEDa..."
      ],
      "Deliver the same criticism diplomatically, ironically, and directly, then explain the interpersonal effect of each version",
      ["Sin \xE1nimo de desmerecer el trabajo...", "No es que est\xE9 mal; quiz\xE1 convendr\xEDa..."],
      "Give a sensitive criticism scenario; require three register-and-stance versions for different relationships plus an explanation of risks",
      "The learner creates three clearly distinct effects, uses at least five frames, and accurately explains the implied attitude"
    ),
    "lesson-c2-7-2": agenda3(
      "C2",
      [
        "con permiso...",
        "disculpe que...",
        "\xBFle importa si...?",
        "muchas felicidades",
        "que lo pasen bien",
        "brindemos por...",
        "gracias por recibirme"
      ],
      "Navigate a social occasion by selecting culturally and relationally appropriate openings, wishes, permissions, and closings",
      ["Con permiso, \xBFle importa si...?", "Brindemos por..."],
      "Simulate arrival, a delicate interruption, a toast, and departure at gatherings with different formality levels",
      "The learner completes all four social moves using at least five appropriate expressions and adjusts address consistently"
    ),
    "lesson-c2-7-3": agenda3(
      "C2",
      [
        "como dice el refr\xE1n...",
        "hace referencia a...",
        "en este contexto...",
        "para quien no conozca...",
        "no debe interpretarse literalmente...",
        "equivale aproximadamente a...",
        "conviene evitar..."
      ],
      "Explain a cultural allusion or saying to an outsider while preserving context, connotation, and variation",
      ["Como dice el refr\xE1n..., que en este contexto...", "No debe interpretarse literalmente"],
      "Present a culturally dense exchange; require explanation of two allusions, a cautious cross-cultural equivalent, and advice against one misreading",
      "The learner makes the references accessible without claiming exact equivalence or presenting a practice as universal",
      { kind: "mediation", evidenceType: "cultural_mediation" }
    ),
    "lesson-c2-8-2": agenda3(
      "C2",
      [
        "claro / ya / aj\xE1",
        "exactamente...",
        "bueno, pero...",
        "perdona que te interrumpa...",
        "sigue, sigue...",
        "\xBFme explico?",
        "digo / quiero decir..."
      ],
      "Manage a fast multi-party exchange through backchanneling, polite interruption, clarification, and self-repair",
      ["Perdona que te interrumpa...", "Digo, quiero decir que..."],
      "Simulate an overlapping discussion with topic shifts and one misunderstanding; require the learner to enter, yield, repair, and redirect",
      "The learner performs all four discourse-management moves naturally and uses at least five target expressions"
    ),
    "lesson-c2-8-3": agenda3(
      "C2",
      [
        "a lo que iba...",
        "dicho de otro modo...",
        "no encuentro la palabra, pero...",
        "viene a ser...",
        "en resumidas cuentas...",
        "retomando lo anterior...",
        "el caso es que..."
      ],
      "Sustain spontaneous extended speech by paraphrasing around gaps, repairing structure, and returning smoothly to the main thread",
      ["No encuentro la palabra, pero viene a ser...", "Retomando lo anterior..."],
      "Elicit an unprepared story with two imposed interruptions and one unavailable key word; require recovery and a concise final synthesis",
      "The learner maintains comprehensibility, recovers from all disruptions, and uses at least five discourse-repair frames naturally"
    )
  });
  var buildAgenda3 = (lessonId, spec, modes) => [
    ...spec.forms.map((form, index) => formItem3(lessonId, index, form, modes)),
    applicationItem3(lessonId, spec.application, modes, spec.forms)
  ];
  function getManualC1C2AgendaItems(lesson, { modes = null } = {}) {
    const lessonId = typeof lesson === "string" ? lesson : lesson?.id;
    const spec = MANUAL_C1_C2_AGENDAS[lessonId];
    if (!spec) return [];
    const lessonModes = modes || (typeof lesson === "object" && Array.isArray(lesson?.modes) ? lesson.modes : ["vocabulary", "realtime"]);
    return buildAgenda3(lessonId, spec, lessonModes);
  }
  function getManualC1C2FoundationFormItems(lesson, { modes = ["vocabulary"] } = {}) {
    const lessonId = typeof lesson === "string" ? lesson : lesson?.id;
    const forms = C1_C2_FOUNDATION_FORMS[lessonId];
    if (!forms) return [];
    return forms.map((form, index) => formItem3(lessonId, index, form, modes));
  }

  // ../nosabos/nosabos/src/data/manualPreA1Agendas.js
  var FORM_LABEL_PREFIXES4 = Object.freeze({
    en: "Use in context",
    es: "Usa en contexto",
    pt: "Use em contexto",
    it: "Usa nel contesto",
    fr: "Utilise en contexte",
    de: "Im Kontext verwenden",
    ja: "\u6587\u8108\u306E\u4E2D\u3067\u4F7F\u3046",
    hi: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
    ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
    zh: "\u5728\u8BED\u5883\u4E2D\u4F7F\u7528"
  });
  var MANUAL_APPLICATION_LABELS = Object.freeze({
    "lesson-pre-a1-1-2": {
      pt: "Identifique e nomeie dois membros da fam\xEDlia extensa",
      it: "Identifica e nomina due membri della famiglia allargata",
      fr: "Identifie et nomme deux membres de la famille \xE9largie",
      de: "Zwei Mitglieder der erweiterten Familie erkennen und benennen",
      ja: "\u89AA\u621A\u30922\u4EBA\u898B\u5206\u3051\u3066\u540D\u524D\u3092\u8A00\u3046",
      hi: "\u0935\u093F\u0938\u094D\u0924\u0943\u0924 \u092A\u0930\u093F\u0935\u093E\u0930 \u0915\u0947 \u0926\u094B \u0938\u0926\u0938\u094D\u092F\u094B\u0902 \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0914\u0930 \u0928\u093E\u092E \u092C\u0924\u093E\u090F\u0902",
      ar: "\u062A\u0639\u0631\u0651\u0641 \u0639\u0644\u0649 \u0641\u0631\u062F\u064A\u0646 \u0645\u0646 \u0627\u0644\u0639\u0627\u0626\u0644\u0629 \u0627\u0644\u0645\u0645\u062A\u062F\u0629 \u0648\u0633\u0645\u0651\u0650\u0647\u0645\u0627",
      zh: "\u8BC6\u522B\u5E76\u8BF4\u51FA\u4E24\u4F4D\u5927\u5BB6\u5EAD\u6210\u5458"
    },
    "lesson-pre-a1-1-3": {
      pt: "Identifique uma pessoa conhecida com mi + palavra de pessoa",
      it: "Identifica una persona conosciuta con mi + parola di persona",
      fr: "Identifie une personne connue avec mi + mot d\xE9signant une personne",
      de: "Eine vertraute Person mit mi + Personenwort benennen",
      ja: "mi\uFF0B\u4EBA\u3092\u8868\u3059\u5358\u8A9E\u3067\u8EAB\u8FD1\u306A\u4EBA\u30921\u4EBA\u793A\u3059",
      hi: "mi + \u0935\u094D\u092F\u0915\u094D\u0924\u093F-\u0938\u0942\u091A\u0915 \u0936\u092C\u094D\u0926 \u0938\u0947 \u0915\u093F\u0938\u0940 \u092A\u0930\u093F\u091A\u093F\u0924 \u0935\u094D\u092F\u0915\u094D\u0924\u093F \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
      ar: "\u062D\u062F\u0651\u062F \u0634\u062E\u0635\u064B\u0627 \u0645\u0623\u0644\u0648\u0641\u064B\u0627 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 mi + \u0643\u0644\u0645\u0629 \u062A\u062F\u0644 \u0639\u0644\u0649 \u0634\u062E\u0635",
      zh: "\u7528 mi + \u4EBA\u7269\u8BCD\u6307\u8BA4\u4E00\u4F4D\u719F\u6089\u7684\u4EBA"
    },
    "lesson-pre-a1-2-2": {
      pt: "Reconhe\xE7a e diga quantidades de seis a dez",
      it: "Riconosci e pronuncia quantit\xE0 da sei a dieci",
      fr: "Reconnais et dis des quantit\xE9s de six \xE0 dix",
      de: "Mengen von sechs bis zehn erkennen und nennen",
      ja: "6\u304B\u308910\u307E\u3067\u306E\u6570\u91CF\u3092\u898B\u5206\u3051\u3066\u8A00\u3046",
      hi: "\u091B\u0939 \u0938\u0947 \u0926\u0938 \u0924\u0915 \u0915\u0940 \u092E\u093E\u0924\u094D\u0930\u093E\u0913\u0902 \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0914\u0930 \u092C\u094B\u0932\u0947\u0902",
      ar: "\u062A\u0639\u0631\u0651\u0641 \u0639\u0644\u0649 \u0627\u0644\u0643\u0645\u064A\u0627\u062A \u0645\u0646 \u0633\u062A\u0629 \u0625\u0644\u0649 \u0639\u0634\u0631\u0629 \u0648\u0642\u0644\u0647\u0627",
      zh: "\u8BC6\u522B\u5E76\u8BF4\u51FA\u516D\u5230\u5341\u7684\u6570\u91CF"
    },
    "lesson-pre-a1-2-3": {
      pt: "Responda a \xBFcu\xE1ntos hay? com um n\xFAmero e um objeto",
      it: "Rispondi a \xBFcu\xE1ntos hay? con un numero e un oggetto",
      fr: "R\xE9ponds \xE0 \xBFcu\xE1ntos hay? avec un nombre et un objet",
      de: "\xBFcu\xE1ntos hay? mit einer Zahl und einem Gegenstand beantworten",
      ja: "\xBFcu\xE1ntos hay? \u306B\u6570\u5B57\u3068\u7269\u3067\u7B54\u3048\u308B",
      hi: "\xBFcu\xE1ntos hay? \u0915\u093E \u0909\u0924\u094D\u0924\u0930 \u090F\u0915 \u0938\u0902\u0916\u094D\u092F\u093E \u0914\u0930 \u0935\u0938\u094D\u0924\u0941 \u0938\u0947 \u0926\u0947\u0902",
      ar: "\u0623\u062C\u0628 \u0639\u0646 \xBFcu\xE1ntos hay? \u0628\u0639\u062F\u062F \u0648\u0634\u064A\u0621",
      zh: "\u7528\u6570\u5B57\u548C\u7269\u54C1\u56DE\u7B54 \xBFcu\xE1ntos hay?"
    },
    "lesson-pre-a1-3-2": {
      pt: "Escolha uma despedida para mais tarde hoje ou amanh\xE3",
      it: "Scegli un saluto per pi\xF9 tardi oggi o per domani",
      fr: "Choisis une formule d\u2019au revoir pour plus tard ou demain",
      de: "Eine Verabschiedung f\xFCr sp\xE4ter heute oder morgen w\xE4hlen",
      ja: "\u4ECA\u65E5\u307E\u305F\u306F\u660E\u65E5\u306B\u5408\u3046\u5225\u308C\u306E\u8868\u73FE\u3092\u9078\u3076",
      hi: "\u0906\u091C \u092C\u093E\u0926 \u092E\u0947\u0902 \u092F\u093E \u0915\u0932 \u0915\u0947 \u0932\u093F\u090F \u0935\u093F\u0926\u093E\u0908 \u0915\u093E \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0639\u0628\u0627\u0631\u0629 \u0648\u062F\u0627\u0639 \u0644\u0648\u0642\u062A \u0644\u0627\u062D\u0642 \u0627\u0644\u064A\u0648\u0645 \u0623\u0648 \u0644\u0644\u063A\u062F",
      zh: "\u9009\u62E9\u9002\u5408\u4ECA\u5929\u7A0D\u540E\u6216\u660E\u5929\u7684\u544A\u522B\u8BED"
    },
    "lesson-pre-a1-3-3": {
      pt: "Complete uma troca de sauda\xE7\xE3o e bem-estar",
      it: "Completa uno scambio di saluti e domande sul benessere",
      fr: "Compl\xE8te un \xE9change de salutations et de nouvelles",
      de: "Einen Begr\xFC\xDFungs- und Befindlichkeitsaustausch vervollst\xE4ndigen",
      ja: "\u6328\u62F6\u3068\u8ABF\u5B50\u3092\u5C0B\u306D\u308B\u3084\u308A\u53D6\u308A\u3092\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u0905\u092D\u093F\u0935\u093E\u0926\u0928 \u0914\u0930 \u0939\u093E\u0932-\u091A\u093E\u0932 \u0915\u093E \u0938\u0902\u0935\u093E\u0926 \u092A\u0942\u0930\u093E \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u062A\u0628\u0627\u062F\u0644\u064B\u0627 \u0644\u0644\u062A\u062D\u064A\u0629 \u0648\u0627\u0644\u0633\u0624\u0627\u0644 \u0639\u0646 \u0627\u0644\u062D\u0627\u0644",
      zh: "\u5B8C\u6210\u4E00\u6BB5\u95EE\u5019\u548C\u8BE2\u95EE\u8FD1\u51B5\u7684\u5BF9\u8BDD"
    },
    "lesson-pre-a1-4-2": {
      pt: "Escolha uma frase de d\xFAvida ou falta de compreens\xE3o",
      it: "Scegli una frase per esprimere dubbio o mancata comprensione",
      fr: "Choisis une phrase de doute ou d\u2019incompr\xE9hension",
      de: "Eine Wendung f\xFCr Unsicherheit oder fehlendes Verst\xE4ndnis w\xE4hlen",
      ja: "\u4E0D\u78BA\u304B\u3055\u3084\u7406\u89E3\u3067\u304D\u306A\u3044\u3053\u3068\u3092\u8868\u3059\u8868\u73FE\u3092\u9078\u3076",
      hi: "\u0905\u0928\u093F\u0936\u094D\u091A\u093F\u0924\u0924\u093E \u092F\u093E \u0938\u092E\u091D \u0928 \u0906\u0928\u0947 \u0915\u0947 \u0932\u093F\u090F \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0639\u0628\u0627\u0631\u0629 \u0644\u0644\u0634\u0643 \u0623\u0648 \u0644\u0639\u062F\u0645 \u0627\u0644\u0641\u0647\u0645",
      zh: "\u9009\u62E9\u8868\u8FBE\u4E0D\u786E\u5B9A\u6216\u4E0D\u7406\u89E3\u7684\u77ED\u8BED"
    },
    "lesson-pre-a1-4-3": {
      pt: "Reaja naturalmente a uma boa not\xEDcia, uma m\xE1 not\xEDcia e uma instru\xE7\xE3o",
      it: "Reagisci in modo naturale a una buona notizia, una cattiva notizia e un\u2019istruzione",
      fr: "R\xE9agis naturellement \xE0 une bonne nouvelle, une mauvaise nouvelle et une consigne",
      de: "Nat\xFCrlich auf gute Nachrichten, schlechte Nachrichten und eine Anweisung reagieren",
      ja: "\u826F\u3044\u77E5\u3089\u305B\u3001\u60AA\u3044\u77E5\u3089\u305B\u3001\u6307\u793A\u306B\u81EA\u7136\u306B\u53CD\u5FDC\u3059\u308B",
      hi: "\u0905\u091A\u094D\u091B\u0940 \u0916\u092C\u0930, \u092C\u0941\u0930\u0940 \u0916\u092C\u0930 \u0914\u0930 \u0928\u093F\u0930\u094D\u0926\u0947\u0936 \u092A\u0930 \u0938\u094D\u0935\u093E\u092D\u093E\u0935\u093F\u0915 \u092A\u094D\u0930\u0924\u093F\u0915\u094D\u0930\u093F\u092F\u093E \u0926\u0947\u0902",
      ar: "\u062A\u0641\u0627\u0639\u0644 \u0628\u0635\u0648\u0631\u0629 \u0637\u0628\u064A\u0639\u064A\u0629 \u0645\u0639 \u062E\u0628\u0631 \u062C\u064A\u062F \u0648\u062E\u0628\u0631 \u0633\u064A\u0626 \u0648\u062A\u0639\u0644\u064A\u0645\u0627\u062A",
      zh: "\u81EA\u7136\u56DE\u5E94\u597D\u6D88\u606F\u3001\u574F\u6D88\u606F\u548C\u6307\u4EE4"
    },
    "lesson-pre-a1-5-2": {
      pt: "Escolha uma desculpa ou frase para chamar a aten\xE7\xE3o conforme a situa\xE7\xE3o",
      it: "Scegli una scusa o una frase per richiamare l\u2019attenzione adatta alla situazione",
      fr: "Choisis une excuse ou une formule pour attirer l\u2019attention selon la situation",
      de: "Eine passende Entschuldigung oder Aufmerksamkeitsformel w\xE4hlen",
      ja: "\u72B6\u6CC1\u306B\u5408\u3046\u8B1D\u7F6A\u307E\u305F\u306F\u547C\u3073\u304B\u3051\u306E\u8868\u73FE\u3092\u9078\u3076",
      hi: "\u0938\u094D\u0925\u093F\u0924\u093F \u0915\u0947 \u0905\u0928\u0941\u0938\u093E\u0930 \u092E\u093E\u092B\u093C\u0940 \u092F\u093E \u0927\u094D\u092F\u093E\u0928 \u0906\u0915\u0930\u094D\u0937\u093F\u0924 \u0915\u0930\u0928\u0947 \u0935\u093E\u0932\u093E \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0639\u0628\u0627\u0631\u0629 \u0627\u0639\u062A\u0630\u0627\u0631 \u0623\u0648 \u0644\u0641\u062A \u0627\u0646\u062A\u0628\u0627\u0647 \u062A\u0646\u0627\u0633\u0628 \u0627\u0644\u0645\u0648\u0642\u0641",
      zh: "\u6839\u636E\u60C5\u5883\u9009\u62E9\u9053\u6B49\u8BED\u6216\u5F15\u8D77\u6CE8\u610F\u7684\u77ED\u8BED"
    },
    "lesson-pre-a1-5-3": {
      pt: "Complete dois pares diferentes de agradecimento e resposta",
      it: "Completa due coppie diverse di ringraziamento e risposta",
      fr: "Compl\xE8te deux \xE9changes diff\xE9rents de remerciement et de r\xE9ponse",
      de: "Zwei verschiedene Dankes- und Antwortpaare vervollst\xE4ndigen",
      ja: "\u7570\u306A\u308B\u611F\u8B1D\u3068\u8FD4\u7B54\u306E\u7D44\u307F\u5408\u308F\u305B\u30922\u3064\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u0927\u0928\u094D\u092F\u0935\u093E\u0926 \u0914\u0930 \u0909\u0924\u094D\u0924\u0930 \u0915\u0947 \u0926\u094B \u0905\u0932\u0917-\u0905\u0932\u0917 \u091C\u094B\u0921\u093C\u0947 \u092A\u0942\u0930\u0947 \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u0632\u0648\u062C\u064A\u0646 \u0645\u062E\u062A\u0644\u0641\u064A\u0646 \u0645\u0646 \u0627\u0644\u0634\u0643\u0631 \u0648\u0627\u0644\u0631\u062F",
      zh: "\u5B8C\u6210\u4E24\u7EC4\u4E0D\u540C\u7684\u611F\u8C22\u4E0E\u56DE\u5E94"
    },
    "lesson-pre-a1-6-2": {
      pt: "Identifique qual objeto pessoal est\xE1 presente ou ausente",
      it: "Identifica quale oggetto personale \xE8 presente o manca",
      fr: "Identifie l\u2019objet personnel pr\xE9sent ou manquant",
      de: "Erkennen, welcher pers\xF6nliche Gegenstand vorhanden ist oder fehlt",
      ja: "\u3042\u308B\u6301\u3061\u7269\u3068\u306A\u3044\u6301\u3061\u7269\u3092\u898B\u5206\u3051\u308B",
      hi: "\u092A\u0939\u091A\u093E\u0928\u0947\u0902 \u0915\u093F \u0915\u094C\u0928-\u0938\u0940 \u0928\u093F\u091C\u0940 \u0935\u0938\u094D\u0924\u0941 \u092E\u094C\u091C\u0942\u0926 \u0939\u0948 \u092F\u093E \u0917\u093E\u092F\u092C \u0939\u0948",
      ar: "\u062D\u062F\u0651\u062F \u0627\u0644\u063A\u0631\u0636 \u0627\u0644\u0634\u062E\u0635\u064A \u0627\u0644\u0645\u0648\u062C\u0648\u062F \u0623\u0648 \u0627\u0644\u0645\u0641\u0642\u0648\u062F",
      zh: "\u8BC6\u522B\u54EA\u4EF6\u4E2A\u4EBA\u7269\u54C1\u5B58\u5728\u6216\u7F3A\u5931"
    },
    "lesson-pre-a1-6-3": {
      pt: "Pe\xE7a uma comida e uma bebida usando por favor",
      it: "Ordina un cibo e una bevanda usando por favor",
      fr: "Commande un aliment et une boisson avec por favor",
      de: "Ein Essen und ein Getr\xE4nk mit por favor bestellen",
      ja: "por favor \u3092\u4F7F\u3063\u3066\u98DF\u3079\u7269\u3068\u98F2\u307F\u7269\u30921\u3064\u305A\u3064\u6CE8\u6587\u3059\u308B",
      hi: "por favor \u0915\u0947 \u0938\u093E\u0925 \u090F\u0915 \u0916\u093E\u0926\u094D\u092F \u0935\u0938\u094D\u0924\u0941 \u0914\u0930 \u090F\u0915 \u092A\u0947\u092F \u092E\u0902\u0917\u093E\u090F\u0902",
      ar: "\u0627\u0637\u0644\u0628 \u0637\u0639\u0627\u0645\u064B\u0627 \u0648\u0634\u0631\u0627\u0628\u064B\u0627 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 por favor",
      zh: "\u7528 por favor \u70B9\u4E00\u79CD\u98DF\u7269\u548C\u4E00\u79CD\u996E\u6599"
    },
    "lesson-pre-a1-7-2": {
      pt: "Identifique quatro cores adicionais em objetos conhecidos",
      it: "Identifica quattro colori aggiuntivi su oggetti familiari",
      fr: "Identifie quatre couleurs suppl\xE9mentaires sur des objets familiers",
      de: "Vier weitere Farben an vertrauten Gegenst\xE4nden erkennen",
      ja: "\u8EAB\u8FD1\u306A\u7269\u306B\u3042\u308B4\u3064\u306E\u8FFD\u52A0\u306E\u8272\u3092\u898B\u5206\u3051\u308B",
      hi: "\u092A\u0930\u093F\u091A\u093F\u0924 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u092A\u0930 \u091A\u093E\u0930 \u0905\u0924\u093F\u0930\u093F\u0915\u094D\u0924 \u0930\u0902\u0917 \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
      ar: "\u062D\u062F\u0651\u062F \u0623\u0631\u0628\u0639\u0629 \u0623\u0644\u0648\u0627\u0646 \u0625\u0636\u0627\u0641\u064A\u0629 \u0639\u0644\u0649 \u0623\u0634\u064A\u0627\u0621 \u0645\u0623\u0644\u0648\u0641\u0629",
      zh: "\u8BC6\u522B\u719F\u6089\u7269\u54C1\u4E0A\u7684\u56DB\u79CD\u5176\u4ED6\u989C\u8272"
    },
    "lesson-pre-a1-7-3": {
      pt: "Escolha e nomeie uma cor neutra",
      it: "Scegli e nomina un colore neutro",
      fr: "Choisis et nomme une couleur neutre",
      de: "Eine neutrale Farbe w\xE4hlen und benennen",
      ja: "\u4E2D\u9593\u8272\u3092\u9078\u3093\u3067\u540D\u524D\u3092\u8A00\u3046",
      hi: "\u090F\u0915 \u0924\u091F\u0938\u094D\u0925 \u0930\u0902\u0917 \u091A\u0941\u0928\u0947\u0902 \u0914\u0930 \u0909\u0938\u0915\u093E \u0928\u093E\u092E \u092C\u0924\u093E\u090F\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0644\u0648\u0646\u064B\u0627 \u0645\u062D\u0627\u064A\u062F\u064B\u0627 \u0648\u0627\u0630\u0643\u0631 \u0627\u0633\u0645\u0647",
      zh: "\u9009\u62E9\u5E76\u8BF4\u51FA\u4E00\u79CD\u4E2D\u6027\u8272"
    },
    "lesson-pre-a1-8-2": {
      pt: "Pergunte o nome de um colega e de um adulto",
      it: "Chiedi il nome a un coetaneo e a un adulto",
      fr: "Demande son nom \xE0 un camarade et \xE0 un adulte",
      de: "Einen Gleichaltrigen und einen Erwachsenen nach dem Namen fragen",
      ja: "\u540C\u5E74\u4EE3\u306E\u4EBA\u3068\u5927\u4EBA\u306B\u540D\u524D\u3092\u5C0B\u306D\u308B",
      hi: "\u0915\u093F\u0938\u0940 \u0939\u092E\u0909\u092E\u094D\u0930 \u0914\u0930 \u0915\u093F\u0938\u0940 \u0935\u092F\u0938\u094D\u0915 \u0938\u0947 \u0909\u0928\u0915\u093E \u0928\u093E\u092E \u092A\u0942\u091B\u0947\u0902",
      ar: "\u0627\u0633\u0623\u0644 \u0634\u062E\u0635\u064B\u0627 \u0645\u0646 \u0623\u0642\u0631\u0627\u0646\u0643 \u0648\u0634\u062E\u0635\u064B\u0627 \u0628\u0627\u0644\u063A\u064B\u0627 \u0639\u0646 \u0627\u0633\u0645\u0647\u0645\u0627",
      zh: "\u8BE2\u95EE\u540C\u9F84\u4EBA\u548C\u6210\u5E74\u4EBA\u7684\u59D3\u540D"
    },
    "lesson-pre-a1-8-3": {
      pt: "Complete duas trocas de prazer em conhecer",
      it: "Completa due scambi per dire piacere di conoscerti",
      fr: "Compl\xE8te deux \xE9changes pour dire enchant\xE9",
      de: "Zwei Kennenlern-Austausche vervollst\xE4ndigen",
      ja: "\u300C\u306F\u3058\u3081\u307E\u3057\u3066\u300D\u306E\u3084\u308A\u53D6\u308A\u30922\u3064\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u092E\u093F\u0932\u0915\u0930 \u0916\u0941\u0936\u0940 \u0939\u0941\u0908 \u0935\u093E\u0932\u0947 \u0926\u094B \u0938\u0902\u0935\u093E\u0926 \u092A\u0942\u0930\u0947 \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u062D\u0648\u0627\u0631\u064A\u0646 \u0644\u0644\u062A\u0639\u0628\u064A\u0631 \u0639\u0646 \u0633\u0631\u0648\u0631 \u0627\u0644\u0644\u0642\u0627\u0621",
      zh: "\u5B8C\u6210\u4E24\u6BB5\u201C\u5F88\u9AD8\u5174\u8BA4\u8BC6\u4F60\u201D\u7684\u5BF9\u8BDD"
    },
    "lesson-a1-1-2": {
      pt: "Complete um encontro de quatro turnos com as frases exigidas",
      it: "Completa un incontro di quattro turni con le frasi richieste",
      fr: "Compl\xE8te une rencontre en quatre tours avec les phrases demand\xE9es",
      de: "Ein Kennenlernen in vier Gespr\xE4chsz\xFCgen mit den vorgegebenen Wendungen abschlie\xDFen",
      ja: "\u6307\u5B9A\u3055\u308C\u305F\u8868\u73FE\u30674\u30BF\u30FC\u30F3\u306E\u521D\u5BFE\u9762\u4F1A\u8A71\u3092\u5B8C\u6210\u3055\u305B\u308B",
      hi: "\u0906\u0935\u0936\u094D\u092F\u0915 \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936\u094B\u0902 \u0915\u0947 \u0938\u093E\u0925 \u091A\u093E\u0930 \u092C\u093E\u0930\u0940 \u0915\u0940 \u092E\u0941\u0932\u093E\u0915\u093E\u0924 \u092A\u0942\u0930\u0940 \u0915\u0930\u0947\u0902",
      ar: "\u0623\u0643\u0645\u0644 \u0644\u0642\u0627\u0621\u064B \u0645\u0646 \u0623\u0631\u0628\u0639 \u0645\u062F\u0627\u062E\u0644\u0627\u062A \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 \u0627\u0644\u0639\u0628\u0627\u0631\u0627\u062A \u0627\u0644\u0645\u0637\u0644\u0648\u0628\u0629",
      zh: "\u4F7F\u7528\u6307\u5B9A\u77ED\u8BED\u5B8C\u6210\u56DB\u8F6E\u521D\u6B21\u89C1\u9762\u5BF9\u8BDD"
    },
    "lesson-a1-1-3": {
      pt: "Escolha linguagem informal ou cort\xEAs para dois primeiros encontros",
      it: "Scegli un linguaggio informale o cortese per due primi incontri",
      fr: "Choisis un registre familier ou poli pour deux premi\xE8res rencontres",
      de: "F\xFCr zwei erste Begegnungen lockere oder h\xF6fliche Sprache w\xE4hlen",
      ja: "2\u3064\u306E\u521D\u5BFE\u9762\u5834\u9762\u3067\u304F\u3060\u3051\u305F\u8868\u73FE\u304B\u4E01\u5BE7\u306A\u8868\u73FE\u3092\u9078\u3076",
      hi: "\u0926\u094B \u092A\u0939\u0932\u0940 \u092E\u0941\u0932\u093E\u0915\u093E\u0924\u094B\u0902 \u0915\u0947 \u0932\u093F\u090F \u0905\u0928\u094C\u092A\u091A\u093E\u0930\u093F\u0915 \u092F\u093E \u0935\u093F\u0928\u092E\u094D\u0930 \u092D\u093E\u0937\u093E \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0644\u063A\u0629 \u0639\u0641\u0648\u064A\u0629 \u0623\u0648 \u0645\u0647\u0630\u0628\u0629 \u0644\u0645\u0648\u0642\u0641\u064A\u0646 \u0645\u0646 \u0627\u0644\u0644\u0642\u0627\u0621 \u0627\u0644\u0623\u0648\u0644",
      zh: "\u4E3A\u4E24\u4E2A\u521D\u6B21\u89C1\u9762\u573A\u666F\u9009\u62E9\u968F\u610F\u6216\u793C\u8C8C\u7684\u8868\u8FBE"
    },
    "lesson-a1-3-2": {
      pt: "Use os n\xFAmeros 11\u201330 para quantidades e um pre\xE7o",
      it: "Usa i numeri 11\u201330 per quantit\xE0 e un prezzo",
      fr: "Utilise les nombres 11\u201330 pour des quantit\xE9s et un prix",
      de: "Die Zahlen 11\u201330 f\xFCr Mengen und einen Preis verwenden",
      ja: "11\uFF5E30\u306E\u6570\u5B57\u3092\u6570\u91CF\u3068\u4FA1\u683C\u306B\u4F7F\u3046",
      hi: "\u092E\u093E\u0924\u094D\u0930\u093E\u0913\u0902 \u0914\u0930 \u090F\u0915 \u0915\u0940\u092E\u0924 \u0915\u0947 \u0932\u093F\u090F 11\u201330 \u0915\u0940 \u0938\u0902\u0916\u094D\u092F\u093E\u0913\u0902 \u0915\u093E \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
      ar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0627\u0644\u0623\u0639\u062F\u0627\u062F 11\u201330 \u0644\u0644\u0643\u0645\u064A\u0627\u062A \u0648\u0644\u0633\u0639\u0631 \u0648\u0627\u062D\u062F",
      zh: "\u4F7F\u752811\u201330\u8868\u793A\u6570\u91CF\u548C\u4E00\u4E2A\u4EF7\u683C"
    },
    "lesson-a1-3-3": {
      pt: "Pergunte e diga uma idade e um n\xFAmero de telefone curto",
      it: "Chiedi e comunica un\u2019et\xE0 e un breve numero di telefono",
      fr: "Demande et donne un \xE2ge et un num\xE9ro de t\xE9l\xE9phone court",
      de: "Nach einem Alter und einer kurzen Telefonnummer fragen und beides angeben",
      ja: "\u5E74\u9F62\u3068\u77ED\u3044\u96FB\u8A71\u756A\u53F7\u3092\u5C0B\u306D\u3066\u7B54\u3048\u308B",
      hi: "\u0909\u092E\u094D\u0930 \u0914\u0930 \u091B\u094B\u091F\u093E \u092B\u093C\u094B\u0928 \u0928\u0902\u092C\u0930 \u092A\u0942\u091B\u0947\u0902 \u0914\u0930 \u092C\u0924\u093E\u090F\u0902",
      ar: "\u0627\u0633\u0623\u0644 \u0639\u0646 \u0639\u0645\u0631 \u0648\u0631\u0642\u0645 \u0647\u0627\u062A\u0641 \u0642\u0635\u064A\u0631 \u0648\u0627\u0630\u0643\u0631\u0647\u0645\u0627",
      zh: "\u8BE2\u95EE\u5E76\u8BF4\u51FA\u5E74\u9F84\u548C\u7B80\u77ED\u7535\u8BDD\u53F7\u7801"
    },
    "lesson-a1-4-2": {
      pt: "Pergunte um pre\xE7o e entenda o total e o troco",
      it: "Chiedi un prezzo e comprendi il totale e il resto",
      fr: "Demande un prix et comprends le total et la monnaie",
      de: "Nach einem Preis fragen und Gesamtbetrag und Wechselgeld verstehen",
      ja: "\u4FA1\u683C\u3092\u5C0B\u306D\u3001\u5408\u8A08\u3068\u304A\u91E3\u308A\u3092\u7406\u89E3\u3059\u308B",
      hi: "\u0915\u0940\u092E\u0924 \u092A\u0942\u091B\u0947\u0902 \u0914\u0930 \u0915\u0941\u0932 \u0930\u093E\u0936\u093F \u0935 \u092C\u093E\u0915\u0940 \u092A\u0948\u0938\u0947 \u0938\u092E\u091D\u0947\u0902",
      ar: "\u0627\u0633\u0623\u0644 \u0639\u0646 \u0627\u0644\u0633\u0639\u0631 \u0648\u0627\u0641\u0647\u0645 \u0627\u0644\u0645\u062C\u0645\u0648\u0639 \u0648\u0627\u0644\u0628\u0627\u0642\u064A",
      zh: "\u8BE2\u95EE\u4EF7\u683C\u5E76\u7406\u89E3\u603B\u4EF7\u548C\u627E\u96F6"
    },
    "lesson-a1-4-3": {
      pt: "Associe os n\xFAmeros 31\u2013100 a pontua\xE7\xF5es, pessoas, pre\xE7os e objetos",
      it: "Abbina i numeri 31\u2013100 a punteggi, persone, prezzi e oggetti",
      fr: "Associe les nombres 31\u2013100 \xE0 des scores, personnes, prix et objets",
      de: "Die Zahlen 31\u2013100 Punkten, Personen, Preisen und Gegenst\xE4nden zuordnen",
      ja: "31\uFF5E100\u306E\u6570\u5B57\u3092\u5F97\u70B9\u3001\u4EBA\u6570\u3001\u4FA1\u683C\u3001\u7269\u306E\u6570\u306B\u5BFE\u5FDC\u3055\u305B\u308B",
      hi: "31\u2013100 \u0915\u0940 \u0938\u0902\u0916\u094D\u092F\u093E\u0913\u0902 \u0915\u094B \u0905\u0902\u0915, \u0932\u094B\u0917, \u0915\u0940\u092E\u0924\u0947\u0902 \u0914\u0930 \u0935\u0938\u094D\u0924\u0941\u0913\u0902 \u0938\u0947 \u092E\u093F\u0932\u093E\u090F\u0902",
      ar: "\u0637\u0627\u0628\u0642 \u0627\u0644\u0623\u0639\u062F\u0627\u062F 31\u2013100 \u0645\u0639 \u0627\u0644\u0646\u0642\u0627\u0637 \u0648\u0627\u0644\u0623\u0634\u062E\u0627\u0635 \u0648\u0627\u0644\u0623\u0633\u0639\u0627\u0631 \u0648\u0627\u0644\u0623\u0634\u064A\u0627\u0621",
      zh: "\u5C0631\u2013100\u4E0E\u5206\u6570\u3001\u4EBA\u6570\u3001\u4EF7\u683C\u548C\u7269\u54C1\u6570\u91CF\u914D\u5BF9"
    },
    "lesson-pre-a1-f-1": {
      pt: "Escolha uma frase inicial para sauda\xE7\xE3o, cortesia ou resposta",
      it: "Scegli una frase iniziale per salutare, essere cortese o rispondere",
      fr: "Choisis une phrase de base pour saluer, \xEAtre poli ou r\xE9pondre",
      de: "Eine erste Wendung zum Begr\xFC\xDFen, f\xFCr H\xF6flichkeit oder zum Antworten w\xE4hlen",
      ja: "\u6328\u62F6\u3001\u4E01\u5BE7\u8868\u73FE\u3001\u8FD4\u7B54\u306B\u4F7F\u3046\u57FA\u672C\u30D5\u30EC\u30FC\u30BA\u3092\u9078\u3076",
      hi: "\u0905\u092D\u093F\u0935\u093E\u0926\u0928, \u0936\u093F\u0937\u094D\u091F\u093E\u091A\u093E\u0930 \u092F\u093E \u0909\u0924\u094D\u0924\u0930 \u0915\u0947 \u0932\u093F\u090F \u0936\u0941\u0930\u0941\u0906\u0924\u0940 \u0935\u093E\u0915\u094D\u092F\u093E\u0902\u0936 \u091A\u0941\u0928\u0947\u0902",
      ar: "\u0627\u062E\u062A\u0631 \u0639\u0628\u0627\u0631\u0629 \u0623\u0633\u0627\u0633\u064A\u0629 \u0644\u0644\u062A\u062D\u064A\u0629 \u0623\u0648 \u0627\u0644\u0645\u062C\u0627\u0645\u0644\u0629 \u0623\u0648 \u0627\u0644\u0631\u062F",
      zh: "\u9009\u62E9\u7528\u4E8E\u95EE\u5019\u3001\u793C\u8C8C\u8868\u8FBE\u6216\u56DE\u5E94\u7684\u5165\u95E8\u77ED\u8BED"
    },
    "lesson-pre-a1-f-2": {
      pt: "Identifique uma pessoa e um lugar com aqu\xED ou all\xED",
      it: "Identifica una persona e un luogo con aqu\xED o all\xED",
      fr: "Identifie une personne et un lieu avec aqu\xED ou all\xED",
      de: "Eine Person und einen Ort mit aqu\xED oder all\xED benennen",
      ja: "aqu\xED \u307E\u305F\u306F all\xED \u3092\u4F7F\u3063\u3066\u4EBA\u3068\u5834\u6240\u3092\u793A\u3059",
      hi: "aqu\xED \u092F\u093E all\xED \u0938\u0947 \u090F\u0915 \u0935\u094D\u092F\u0915\u094D\u0924\u093F \u0914\u0930 \u0938\u094D\u0925\u093E\u0928 \u0915\u094B \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
      ar: "\u062D\u062F\u0651\u062F \u0634\u062E\u0635\u064B\u0627 \u0648\u0645\u0643\u0627\u0646\u064B\u0627 \u0628\u0627\u0633\u062A\u062E\u062F\u0627\u0645 aqu\xED \u0623\u0648 all\xED",
      zh: "\u7528 aqu\xED \u6216 all\xED \u6307\u8BA4\u4E00\u4E2A\u4EBA\u548C\u4E00\u4E2A\u5730\u70B9"
    },
    "lesson-pre-a1-f-3": {
      pt: "Expresse um desejo e uma necessidade imediata",
      it: "Esprimi un desiderio e un bisogno immediato",
      fr: "Exprime un souhait et un besoin imm\xE9diat",
      de: "Einen Wunsch und ein unmittelbares Bed\xFCrfnis ausdr\xFCcken",
      ja: "\u6B32\u3057\u3044\u3082\u306E\u3068\u4ECA\u5FC5\u8981\u306A\u3082\u306E\u30921\u3064\u305A\u3064\u8868\u73FE\u3059\u308B",
      hi: "\u090F\u0915 \u0907\u091A\u094D\u091B\u093E \u0914\u0930 \u090F\u0915 \u0924\u0924\u094D\u0915\u093E\u0932 \u0906\u0935\u0936\u094D\u092F\u0915\u0924\u093E \u0935\u094D\u092F\u0915\u094D\u0924 \u0915\u0930\u0947\u0902",
      ar: "\u0639\u0628\u0651\u0631 \u0639\u0646 \u0631\u063A\u0628\u0629 \u0648\u0627\u062D\u062F\u0629 \u0648\u062D\u0627\u062C\u0629 \u0641\u0648\u0631\u064A\u0629 \u0648\u0627\u062D\u062F\u0629",
      zh: "\u8868\u8FBE\u4E00\u4E2A\u613F\u671B\u548C\u4E00\u4E2A\u5373\u65F6\u9700\u6C42"
    },
    "lesson-pre-a1-f-4": {
      pt: "Siga uma indica\xE7\xE3o de tempo e uma dire\xE7\xE3o simples",
      it: "Segui un\u2019indicazione di tempo e una direzione semplice",
      fr: "Suis une indication de temps et une direction simple",
      de: "Einem Zeithinweis und einer einfachen Richtungsangabe folgen",
      ja: "\u6642\u9593\u306E\u5408\u56F3\u3068\u7C21\u5358\u306A\u65B9\u5411\u6307\u793A\u306B\u5F93\u3046",
      hi: "\u0938\u092E\u092F \u0915\u0947 \u090F\u0915 \u0938\u0902\u0915\u0947\u0924 \u0914\u0930 \u090F\u0915 \u0938\u0930\u0932 \u0926\u093F\u0936\u093E-\u0928\u093F\u0930\u094D\u0926\u0947\u0936 \u0915\u093E \u092A\u093E\u0932\u0928 \u0915\u0930\u0947\u0902",
      ar: "\u0627\u062A\u0628\u0639 \u0625\u0634\u0627\u0631\u0629 \u0632\u0645\u0646\u064A\u0629 \u0648\u0627\u062D\u062F\u0629 \u0648\u0627\u062A\u062C\u0627\u0647\u064B\u0627 \u0628\u0633\u064A\u0637\u064B\u0627 \u0648\u0627\u062D\u062F\u064B\u0627",
      zh: "\u9075\u5FAA\u4E00\u4E2A\u65F6\u95F4\u63D0\u793A\u548C\u4E00\u4E2A\u7B80\u5355\u65B9\u5411\u6307\u793A"
    }
  });
  var formItem4 = (lessonId, index, form, modes) => ({
    id: `manual-${lessonId}-form-${index + 1}`,
    kind: "vocabulary",
    modes,
    label: Object.fromEntries(
      Object.entries(FORM_LABEL_PREFIXES4).map(([lang, prefix]) => [
        lang,
        `${prefix}: ${form}`
      ])
    ),
    goal: `Recognize and produce "${form}"`,
    targetConcept: form,
    targetRole: "form",
    targetForms: [form],
    targetExamples: [form],
    activityBrief: "Give the meaning and one tiny situation for this exact word or phrase, then ask for one recognition or production attempt",
    evidence: {
      type: "produce_or_choose",
      criteria: `The learner recognizes or understandably produces "${form}"`
    },
    source: "manual-pre-a1-agenda",
    spanishOnly: true
  });
  var capabilityItem = (lessonId, spec, modes) => ({
    id: `manual-${lessonId}-application`,
    kind: spec.kind || "communication",
    modes,
    label: {
      en: spec.en,
      es: spec.es,
      ...MANUAL_APPLICATION_LABELS[lessonId]
    },
    goal: spec.goal,
    targetConcept: spec.goal,
    targetRole: "goal",
    targetForms: [],
    targetExamples: spec.examples || [],
    activityBrief: spec.activityBrief,
    evidence: {
      type: spec.evidenceType || "scenario_response",
      criteria: spec.evidence
    },
    source: "manual-pre-a1-agenda",
    spanishOnly: true
  });
  var agenda4 = (forms, application) => ({ forms, application });
  var MANUAL_PRE_A1_AGENDAS = Object.freeze({
    "lesson-pre-a1-1-2": agenda4(
      ["abuelo", "abuela", "beb\xE9", "t\xEDo", "t\xEDa"],
      {
        en: "Identify and name two extended-family members",
        es: "Identifica y nombra a dos familiares",
        goal: "Identify and name at least two extended-family members",
        examples: ["Es mi abuela.", "Es mi t\xEDo."],
        activityBrief: "Show or describe two family relationships and ask the learner to name them",
        evidence: "The learner correctly names at least two extended-family members"
      }
    ),
    "lesson-pre-a1-1-3": agenda4(
      ["amigo", "amiga", "vecino", "vecina", "ni\xF1o", "ni\xF1a"],
      {
        en: "Identify one familiar person with mi + person word",
        es: "Identifica a una persona con mi + palabra de persona",
        goal: "Identify one familiar person using mi plus a people word",
        examples: ["Mi amiga.", "Mi vecino."],
        activityBrief: "Present one familiar person and help the learner identify the relationship with a two-word chunk",
        evidence: "The learner produces an understandable mi plus person phrase"
      }
    ),
    "lesson-pre-a1-2-2": agenda4(
      ["seis", "siete", "ocho", "nueve", "diez"],
      {
        en: "Recognize and say quantities from six to ten",
        es: "Reconoce y di cantidades del seis al diez",
        goal: "Recognize and produce quantities from six to ten",
        examples: ["seis libros", "nueve sillas"],
        activityBrief: "Present three small quantities from six to ten and ask the learner to identify or say each number",
        evidence: "The learner correctly recognizes or produces at least three numbers from six to ten"
      }
    ),
    "lesson-pre-a1-2-3": agenda4(
      ["un libro", "dos libros", "tres sillas", "cuatro mesas", "\xBFcu\xE1ntos hay?"],
      {
        en: "Answer \xBFcu\xE1ntos hay? with a number and an object",
        es: "Responde \xBFcu\xE1ntos hay? con un n\xFAmero y un objeto",
        goal: "Answer a quantity question with a number and a familiar object",
        examples: ["Dos libros.", "Cuatro mesas."],
        activityBrief: "Ask one quantity question at a time about familiar objects and elicit a number-plus-object answer",
        evidence: "The learner gives two understandable number-plus-object answers"
      }
    ),
    "lesson-pre-a1-3-2": agenda4(
      ["adi\xF3s", "hasta luego", "hasta ma\xF1ana", "nos vemos", "chao"],
      {
        en: "Choose a farewell for later today or tomorrow",
        es: "Elige una despedida para m\xE1s tarde o ma\xF1ana",
        goal: "Choose an appropriate farewell for two simple time contexts",
        examples: ["Hasta luego.", "Hasta ma\xF1ana."],
        activityBrief: "Give a later-today context and a tomorrow context, asking for one appropriate farewell in each",
        evidence: "The learner chooses an appropriate farewell in both contexts"
      }
    ),
    "lesson-pre-a1-3-3": agenda4(
      ["hola", "\xBFc\xF3mo est\xE1s?", "bien, gracias", "\xBFy t\xFA?", "bienvenido"],
      {
        en: "Complete a greeting and wellbeing exchange",
        es: "Completa un saludo y un intercambio de bienestar",
        goal: "Complete a short greeting and wellbeing exchange",
        examples: ["Hola. \xBFC\xF3mo est\xE1s?", "Bien, gracias. \xBFY t\xFA?"],
        activityBrief: "Run a three-turn arrival exchange using a greeting, a wellbeing question, and a short response",
        evidence: "The learner supplies the appropriate greeting or response in three consecutive turns"
      }
    ),
    "lesson-pre-a1-4-2": agenda4(
      ["no s\xE9", "quiz\xE1s", "tal vez", "m\xE1s o menos", "no entiendo"],
      {
        en: "Choose a phrase for uncertainty or lack of understanding",
        es: "Elige una frase de duda o falta de comprensi\xF3n",
        goal: "Distinguish uncertainty from not knowing and not understanding",
        examples: ["Quiz\xE1s.", "No s\xE9.", "No entiendo."],
        activityBrief: "Give one maybe, one unknown, and one comprehension situation and ask for the matching short response",
        evidence: "The learner chooses an appropriate response for at least two different situations"
      }
    ),
    "lesson-pre-a1-4-3": agenda4(
      ["entiendo", "claro", "vale", "bien", "mal", "qu\xE9 bien"],
      {
        en: "React naturally to good news, bad news, and an instruction",
        es: "Reacciona a una buena noticia, una mala noticia y una instrucci\xF3n",
        goal: "Use three different short reactions in matching contexts",
        examples: ["\xA1Qu\xE9 bien!", "Mal.", "Vale."],
        activityBrief: "Give three tiny contexts\u2014good news, bad news, and a simple instruction\u2014and elicit a different reaction",
        evidence: "The learner gives three context-appropriate short reactions"
      }
    ),
    "lesson-pre-a1-5-2": agenda4(
      ["perd\xF3n", "lo siento", "disculpe", "con permiso"],
      {
        en: "Choose an apology or attention phrase for the situation",
        es: "Elige una disculpa o frase de atenci\xF3n seg\xFAn la situaci\xF3n",
        goal: "Distinguish apologizing, getting attention, and passing by",
        examples: ["Lo siento.", "Disculpe.", "Con permiso."],
        activityBrief: "Give one bumping-into-someone situation, one attention situation, and one passing-by situation",
        evidence: "The learner chooses the appropriate phrase in at least two different situations"
      }
    ),
    "lesson-pre-a1-5-3": agenda4(
      ["muchas gracias", "de nada", "no hay problema", "con gusto", "no es nada"],
      {
        en: "Complete two different thank-you and response pairs",
        es: "Completa dos pares distintos de agradecimiento y respuesta",
        goal: "Complete two courtesy exchanges using different responses",
        examples: ["Muchas gracias. \u2014 De nada.", "Gracias. \u2014 Con gusto."],
        activityBrief: "Model one thank-you exchange, then prompt two new exchanges that require different courtesy responses",
        evidence: "The learner completes two exchanges with two different appropriate courtesy responses"
      }
    ),
    "lesson-pre-a1-6-2": agenda4(
      ["llave", "tel\xE9fono", "cartera", "bolso", "libro", "l\xE1piz"],
      {
        en: "Identify which personal item is present or missing",
        es: "Identifica qu\xE9 objeto personal est\xE1 o falta",
        goal: "Identify familiar personal items in a bag or missing-item context",
        examples: ["Mi tel\xE9fono.", "Falta la llave."],
        activityBrief: "Describe a bag with three familiar items, then ask which item is present or missing",
        evidence: "The learner correctly identifies at least three personal items",
        kind: "comprehension",
        evidenceType: "identify"
      }
    ),
    "lesson-pre-a1-6-3": agenda4(
      ["agua", "caf\xE9", "t\xE9", "leche", "pan", "comida"],
      {
        en: "Order one food and one drink with por favor",
        es: "Pide una comida y una bebida con por favor",
        goal: "Order one familiar food and one familiar drink politely",
        examples: ["Caf\xE9, por favor.", "Pan, por favor."],
        activityBrief: "Offer a tiny caf\xE9 menu and ask the learner to request one drink and one food item",
        evidence: "The learner makes two understandable item-plus-por-favor requests"
      }
    ),
    "lesson-pre-a1-7-2": agenda4(
      ["verde", "naranja", "morado", "rosa"],
      {
        en: "Identify four additional colors on familiar objects",
        es: "Identifica cuatro colores adicionales en objetos conocidos",
        goal: "Identify and name four additional colors",
        examples: ["libro verde", "mesa naranja"],
        activityBrief: "Pair each new color with a familiar object and ask the learner to identify the color",
        evidence: "The learner correctly names at least three of the four colors"
      }
    ),
    "lesson-pre-a1-7-3": agenda4(
      ["negro", "blanco", "gris", "marr\xF3n"],
      {
        en: "Choose and name a neutral color",
        es: "Elige y nombra un color neutro",
        goal: "Recognize and use black, white, gray, and brown",
        examples: ["puerta blanca", "mesa marr\xF3n"],
        activityBrief: "Present familiar objects in neutral colors and ask the learner to name or choose the color",
        evidence: "The learner correctly uses at least three neutral color words"
      }
    ),
    "lesson-pre-a1-8-2": agenda4(
      ["\xBFc\xF3mo te llamas?", "\xBFc\xF3mo se llama?", "\xBFy t\xFA?", "tu nombre"],
      {
        en: "Ask a peer and an adult for their name",
        es: "Pregunta el nombre de un compa\xF1ero y de un adulto",
        goal: "Ask for a name using one casual and one polite question",
        examples: ["\xBFC\xF3mo te llamas?", "\xBFC\xF3mo se llama?"],
        activityBrief: "Present one peer and one adult context and ask the learner to choose and produce the appropriate name question",
        evidence: "The learner produces the casual and polite name questions in the matching contexts"
      }
    ),
    "lesson-pre-a1-8-3": agenda4(
      ["mucho gusto", "encantado", "encantada", "igualmente", "un placer"],
      {
        en: "Complete two nice-to-meet-you exchanges",
        es: "Completa dos intercambios de mucho gusto",
        goal: "Use and respond to a nice-to-meet-you expression",
        examples: ["Mucho gusto. \u2014 Igualmente.", "Encantada. \u2014 Un placer."],
        activityBrief: "Run two first-meeting closings and require a greeting response rather than another introduction",
        evidence: "The learner appropriately opens or responds to two nice-to-meet-you exchanges"
      }
    ),
    "lesson-a1-1-2": agenda4(
      [
        "hola",
        "me llamo",
        "\xBFc\xF3mo te llamas?",
        "mucho gusto",
        "\xBFc\xF3mo est\xE1s?",
        "bien, gracias",
        "hasta luego"
      ],
      {
        en: "Complete a four-turn meeting with the required phrases",
        es: "Completa un encuentro de cuatro turnos con las frases requeridas",
        goal: "Complete a four-turn first meeting using a greeting, names, wellbeing, and a closing",
        examples: [
          "Hola. Me llamo Ana.",
          "Mucho gusto. \xBFC\xF3mo est\xE1s?",
          "Bien, gracias. Hasta luego."
        ],
        activityBrief: "Run exactly four short turns: greeting, name exchange, wellbeing exchange, and closing; prompt only the missing phrase",
        evidence: "The learner completes all four stages with an understandable required phrase"
      }
    ),
    "lesson-a1-1-3": agenda4(
      [
        "hola",
        "buenos d\xEDas",
        "\xBFc\xF3mo est\xE1s?",
        "\xBFc\xF3mo est\xE1 usted?",
        "\xBFc\xF3mo te llamas?",
        "\xBFc\xF3mo se llama?"
      ],
      {
        en: "Choose casual or polite language for two first meetings",
        es: "Elige lenguaje casual o cort\xE9s para dos encuentros",
        goal: "Distinguish casual and polite greeting and name questions",
        examples: ["Hola. \xBFC\xF3mo est\xE1s?", "Buenos d\xEDas. \xBFC\xF3mo est\xE1 usted?"],
        activityBrief: "Present a peer context and an adult-stranger context, requiring the matching greeting and question in each",
        evidence: "The learner chooses the appropriate register in both contexts"
      }
    ),
    "lesson-a1-3-2": agenda4(
      ["hay doce", "hay veinte", "son quince", "cuesta veinticinco", "\xBFcu\xE1ntos hay?"],
      {
        en: "Use numbers 11\u201330 for quantities and a price",
        es: "Usa los n\xFAmeros 11\u201330 para cantidades y un precio",
        goal: "State two quantities and one price using numbers 11\u201330",
        examples: ["Hay doce libros.", "Cuesta veinticinco."],
        activityBrief: "Ask two how-many questions and one simple price question using authored numbers from 11 to 30",
        evidence: "The learner produces two correct quantities and one understandable price"
      }
    ),
    "lesson-a1-3-3": agenda4(
      ["mi n\xFAmero es", "\xBFcu\xE1l es tu n\xFAmero?", "tengo veinte a\xF1os", "\xBFcu\xE1ntos a\xF1os tienes?"],
      {
        en: "Ask for and give an age and a short phone number",
        es: "Pregunta y da una edad y un n\xFAmero de tel\xE9fono corto",
        goal: "Ask for and give one age and one short phone number",
        examples: ["Tengo veinte a\xF1os.", "Mi n\xFAmero es 21 15 30."],
        activityBrief: "Use fictional information: exchange one age and one short grouped phone number",
        evidence: "The learner asks for or gives both an age and a short phone number"
      }
    ),
    "lesson-a1-4-2": agenda4(
      ["\xBFcu\xE1nto cuesta?", "cuesta cuarenta", "son cincuenta pesos", "cambio, por favor"],
      {
        en: "Ask a price and understand the total and change",
        es: "Pregunta un precio y entiende el total y el cambio",
        goal: "Ask for a price, state a total, and request change",
        examples: ["\xBFCu\xE1nto cuesta?", "Son cincuenta pesos."],
        activityBrief: "Run a tiny purchase with one price question, one total from 31 to 100, and one change request",
        evidence: "The learner completes the price question and responds correctly to the total"
      }
    ),
    "lesson-a1-4-3": agenda4(
      ["treinta puntos", "sesenta personas", "noventa pesos", "cien libros"],
      {
        en: "Match numbers 31\u2013100 to scores, people, prices, and objects",
        es: "Relaciona n\xFAmeros 31\u2013100 con puntos, personas, precios y objetos",
        goal: "Interpret and produce numbers 31\u2013100 in four concrete contexts",
        examples: ["Sesenta personas.", "Noventa pesos."],
        activityBrief: "Present a score, a headcount, a price, and an object quantity; ask for one number phrase at a time",
        evidence: "The learner correctly interprets or produces at least three of the four number phrases"
      }
    ),
    "lesson-pre-a1-f-1": agenda4(
      ["hola", "buenos d\xEDas", "adi\xF3s", "gracias", "por favor", "s\xED", "no", "no s\xE9"],
      {
        en: "Choose a starter phrase for greeting, courtesy, or response",
        es: "Elige una frase inicial de saludo, cortes\xEDa o respuesta",
        goal: "Use high-frequency starter phrases in matching situations",
        examples: ["Buenos d\xEDas.", "S\xED, por favor.", "No s\xE9."],
        activityBrief: "Cycle through a greeting, a polite request, a yes/no choice, and an unknown-answer situation",
        evidence: "The learner gives an appropriate phrase in four different starter situations"
      }
    ),
    "lesson-pre-a1-f-2": agenda4(
      ["mam\xE1", "pap\xE1", "amigo", "casa", "escuela", "trabajo", "aqu\xED", "all\xED"],
      {
        en: "Identify a person and a place with aqu\xED or all\xED",
        es: "Identifica una persona y un lugar con aqu\xED o all\xED",
        goal: "Identify familiar people and places using here and there",
        examples: ["Mam\xE1 est\xE1 aqu\xED.", "La escuela est\xE1 all\xED."],
        activityBrief: "Present two familiar people and two familiar places, asking where each one is",
        evidence: "The learner correctly identifies at least one person and two places"
      }
    ),
    "lesson-pre-a1-f-3": agenda4(
      ["quiero", "necesito", "tengo", "voy", "ayuda", "agua", "comida", "ba\xF1o"],
      {
        en: "Express one want and one immediate need",
        es: "Expresa un deseo y una necesidad inmediata",
        goal: "Use quiero or necesito with an immediate essential",
        examples: ["Quiero agua.", "Necesito ayuda."],
        activityBrief: "Give one choice situation and one help situation, eliciting a two-word want or need phrase",
        evidence: "The learner produces one understandable quiero phrase and one necesito phrase"
      }
    ),
    "lesson-pre-a1-f-4": agenda4(
      [
        "hoy",
        "ma\xF1ana",
        "ahora",
        "aqu\xED",
        "all\xED",
        "izquierda",
        "derecha",
        "recto",
        "autob\xFAs",
        "taxi"
      ],
      {
        en: "Follow one time cue and one simple direction",
        es: "Sigue una indicaci\xF3n de tiempo y una direcci\xF3n sencilla",
        goal: "Recognize basic time, transport, and direction words",
        examples: ["Ahora, a la derecha.", "Taxi aqu\xED."],
        activityBrief: "Give one when choice, one transport choice, and two one-step directions",
        evidence: "The learner correctly responds to a time cue, a transport word, and two directions"
      }
    )
  });
  var buildAgenda4 = (lessonId, spec, modes) => [
    ...spec.forms.map((form, index) => formItem4(lessonId, index, form, modes)),
    capabilityItem(lessonId, spec.application, modes)
  ];
  function getManualPreA1AgendaItems(lesson, { modes = null } = {}) {
    const lessonId = typeof lesson === "string" ? lesson : lesson?.id;
    const spec = MANUAL_PRE_A1_AGENDAS[lessonId];
    if (!spec) return [];
    const lessonModes = modes || (typeof lesson === "object" && Array.isArray(lesson?.modes) ? lesson.modes : ["vocabulary", "realtime"]);
    return buildAgenda4(lessonId, spec, lessonModes);
  }

  // ../nosabos/nosabos/src/utils/lessonCurriculum.js
  var INVALID_OBJECTIVE_LABELS = /* @__PURE__ */ new Set([
    "form",
    "use",
    "form and use",
    "pattern recycling",
    "micro-drills",
    "micro drills",
    "general vocabulary and grammar",
    "comprehensive review",
    "lesson focus"
  ]);
  var REVIEW_LESSON_ID_PARTS = [
    "skill-builder",
    "integrated-practice",
    "-quiz",
    "-game"
  ];
  var MODE_KIND = {
    vocabulary: "vocabulary",
    grammar: "grammar",
    reading: "comprehension",
    stories: "comprehension",
    realtime: "communication",
    game: "communication"
  };
  var AGENDA_TARGET_ROLES = /* @__PURE__ */ new Set(["form", "goal"]);
  var EXACT_FORM_MODES = /* @__PURE__ */ new Set(["vocabulary"]);
  var INSTRUCTIONAL_OBJECTIVE_PATTERN = /^(?:ask|complete|demonstrate|describe|discuss|follow|interpret|learn|listen|practice|read|repeat|roleplay|tell|the learner|the user|use only|write)\b/i;
  var MODE_LABELS = {
    en: {
      vocabulary: "Use in context",
      grammar: "Use accurately",
      reading: "Recognize in a text",
      stories: "Understand in a story",
      realtime: "Use in conversation",
      game: "Apply in a review"
    },
    es: {
      vocabulary: "Usa en contexto",
      grammar: "Usa con precisi\xF3n",
      reading: "Reconoce en un texto",
      stories: "Comprende en una historia",
      realtime: "Usa en conversaci\xF3n",
      game: "Aplica en un repaso"
    },
    pt: {
      vocabulary: "Use em contexto",
      grammar: "Use com precis\xE3o",
      reading: "Reconhe\xE7a em um texto",
      stories: "Compreenda em uma hist\xF3ria",
      realtime: "Use em uma conversa",
      game: "Aplique em uma revis\xE3o"
    },
    it: {
      vocabulary: "Usa nel contesto",
      grammar: "Usa con precisione",
      reading: "Riconosci in un testo",
      stories: "Comprendi in una storia",
      realtime: "Usa in una conversazione",
      game: "Applica in un ripasso"
    },
    fr: {
      vocabulary: "Utilise en contexte",
      grammar: "Utilise avec pr\xE9cision",
      reading: "Rep\xE8re dans un texte",
      stories: "Comprends dans une histoire",
      realtime: "Utilise dans une conversation",
      game: "Applique dans une r\xE9vision"
    },
    de: {
      vocabulary: "Im Kontext verwenden",
      grammar: "Korrekt verwenden",
      reading: "In einem Text erkennen",
      stories: "In einer Geschichte verstehen",
      realtime: "Im Gespr\xE4ch verwenden",
      game: "In einer Wiederholung anwenden"
    },
    ja: {
      vocabulary: "\u6587\u8108\u306E\u4E2D\u3067\u4F7F\u3046",
      grammar: "\u6B63\u78BA\u306B\u4F7F\u3046",
      reading: "\u6587\u7AE0\u306E\u4E2D\u3067\u898B\u5206\u3051\u308B",
      stories: "\u7269\u8A9E\u306E\u4E2D\u3067\u7406\u89E3\u3059\u308B",
      realtime: "\u4F1A\u8A71\u306E\u4E2D\u3067\u4F7F\u3046",
      game: "\u5FA9\u7FD2\u3067\u5FDC\u7528\u3059\u308B"
    },
    hi: {
      vocabulary: "\u0938\u0902\u0926\u0930\u094D\u092D \u092E\u0947\u0902 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
      grammar: "\u0938\u091F\u0940\u0915 \u0930\u0942\u092A \u0938\u0947 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
      reading: "\u092A\u093E\u0920 \u092E\u0947\u0902 \u092A\u0939\u091A\u093E\u0928\u0947\u0902",
      stories: "\u0915\u0939\u093E\u0928\u0940 \u092E\u0947\u0902 \u0938\u092E\u091D\u0947\u0902",
      realtime: "\u092C\u093E\u0924\u091A\u0940\u0924 \u092E\u0947\u0902 \u0909\u092A\u092F\u094B\u0917 \u0915\u0930\u0947\u0902",
      game: "\u0938\u092E\u0940\u0915\u094D\u0937\u093E \u092E\u0947\u0902 \u0932\u093E\u0917\u0942 \u0915\u0930\u0947\u0902"
    },
    ar: {
      vocabulary: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0641\u064A \u0627\u0644\u0633\u064A\u0627\u0642",
      grammar: "\u0627\u0633\u062A\u062E\u062F\u0645 \u0628\u062F\u0642\u0629",
      reading: "\u062A\u0639\u0631\u0651\u0641 \u0639\u0644\u064A\u0647 \u0641\u064A \u0646\u0635",
      stories: "\u0627\u0641\u0647\u0645\u0647 \u0641\u064A \u0642\u0635\u0629",
      realtime: "\u0627\u0633\u062A\u062E\u062F\u0645\u0647 \u0641\u064A \u0645\u062D\u0627\u062F\u062B\u0629",
      game: "\u0637\u0628\u0651\u0642\u0647 \u0641\u064A \u0645\u0631\u0627\u062C\u0639\u0629"
    },
    zh: {
      vocabulary: "\u5728\u8BED\u5883\u4E2D\u4F7F\u7528",
      grammar: "\u51C6\u786E\u4F7F\u7528",
      reading: "\u5728\u6587\u672C\u4E2D\u8BC6\u522B",
      stories: "\u5728\u6545\u4E8B\u4E2D\u7406\u89E3",
      realtime: "\u5728\u5BF9\u8BDD\u4E2D\u4F7F\u7528",
      game: "\u5728\u590D\u4E60\u4E2D\u8FD0\u7528"
    }
  };
  var EVIDENCE_BY_MODE = {
    vocabulary: {
      type: "produce_or_choose",
      criteria: "Uses or identifies the specified vocabulary in context"
    },
    grammar: {
      type: "produce_or_choose",
      criteria: "Uses or identifies the specified structure accurately"
    },
    reading: {
      type: "identify",
      criteria: "Identifies the specified meaning or form in written context"
    },
    stories: {
      type: "comprehend_and_respond",
      criteria: "Understands and responds using the specified lesson material"
    },
    realtime: {
      type: "scenario_response",
      criteria: "Completes the specified communicative action understandably"
    },
    game: {
      type: "scenario_response",
      criteria: "Applies the specified lesson material in the review scenario"
    }
  };
  var cleanText = (value) => String(value || "").replace(/\s+/g, " ").trim();
  var normalizeObjectiveKey = (value) => cleanText(value).normalize("NFD").replace(/[\u0300-\u036f]/g, "").toLowerCase().replace(/[¿?¡!.,;:"'()[\]{}]/g, " ").replace(/\s+/g, " ").trim();
  var slugify = (value) => normalizeObjectiveKey(value).replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 52) || "objective";
  var getDisplayText = (value, lang = "en") => {
    if (typeof value === "string") return cleanText(value);
    if (!value || typeof value !== "object") return "";
    return cleanText(
      value[lang] || value.en || value.es || Object.values(value).find(Boolean)
    );
  };
  var getManualSpanishAgendaItems = (lesson, options) => {
    const preA1Items = getManualPreA1AgendaItems(lesson, options);
    if (preA1Items.length) return preA1Items;
    const a1Items = getManualA1AgendaItems(lesson, options);
    if (a1Items.length) return a1Items;
    const b1B2Items = getManualB1B2AgendaItems(lesson, options);
    return b1B2Items.length ? b1B2Items : getManualC1C2AgendaItems(lesson, options);
  };
  var getManualSpanishFoundationFormItems = (lesson, options) => {
    const b1B2Items = getManualB1B2FoundationFormItems(lesson, options);
    return b1B2Items.length ? b1B2Items : getManualC1C2FoundationFormItems(lesson, options);
  };
  var uniqueText = (values = []) => {
    const seen = /* @__PURE__ */ new Set();
    return values.filter((value) => {
      const key = normalizeObjectiveKey(value);
      if (!key || seen.has(key)) return false;
      seen.add(key);
      return true;
    });
  };
  var extractItemText = (value) => {
    if (typeof value === "string" || typeof value === "number") {
      return cleanText(value);
    }
    if (!value || typeof value !== "object") return "";
    return cleanText(
      value.target || value.word || value.phrase || value.answer || value.label || value.text
    );
  };
  var normalizeTextList = (value) => uniqueText(
    (Array.isArray(value) ? value : value ? [value] : []).map(extractItemText).filter(Boolean)
  );
  function isInstructionalLessonObjective(value) {
    const text = cleanText(value);
    const words = text.match(/[\p{L}\p{M}\p{N}]+/gu) || [];
    if (words.length <= 1) return false;
    if (/[,/|]/.test(text) && words.length <= 12) return false;
    return INSTRUCTIONAL_OBJECTIVE_PATTERN.test(text);
  }
  function getAgendaTargetRole(item = {}) {
    if (AGENDA_TARGET_ROLES.has(item.targetRole)) return item.targetRole;
    if (normalizeTextList(item.targetForms).length) return "form";
    const mode = item.modes?.find((candidate) => MODE_KIND[candidate]) || Object.entries(MODE_KIND).find(([, kind]) => kind === item.kind)?.[0] || "";
    const concept = cleanText(item.targetConcept);
    return EXACT_FORM_MODES.has(mode) && !isInstructionalLessonObjective(concept) ? "form" : "goal";
  }
  function getAgendaTargetForms(item = {}) {
    const explicit = normalizeTextList(item.targetForms);
    if (explicit.length) return explicit;
    if (getAgendaTargetRole(item) !== "form") return [];
    return normalizeTextList(item.targetConcept);
  }
  function getAgendaGoal(item = {}) {
    return cleanText(item.goal) || cleanText(item.targetConcept) || getDisplayText(item.label, "en");
  }
  function normalizeAgendaItemSemantics(item = {}) {
    const targetRole = getAgendaTargetRole(item);
    const targetForms = targetRole === "form" ? getAgendaTargetForms(item) : normalizeTextList(item.targetForms);
    return {
      ...item,
      goal: getAgendaGoal(item),
      targetRole,
      targetForms,
      activityBrief: cleanText(item.activityBrief)
    };
  }
  function isInvalidLessonObjective(value) {
    const normalized = normalizeObjectiveKey(value);
    if (!normalized) return true;
    if (INVALID_OBJECTIVE_LABELS.has(normalized)) return true;
    if (/^(?:form|use|practice|review|vocabulary|grammar)$/.test(normalized)) {
      return true;
    }
    return false;
  }
  function isReviewLesson(lesson) {
    const id = String(lesson?.id || "").toLowerCase();
    return !!lesson?.isFinalQuiz || !!lesson?.isGame || REVIEW_LESSON_ID_PARTS.some((part) => id.includes(part));
  }
  function getConcreteModeObjectives(block = {}) {
    const explicit = [
      ...Array.isArray(block.focusPoints) ? block.focusPoints : [],
      ...Array.isArray(block.topics) ? block.topics : [],
      ...Array.isArray(block.words) ? block.words : [],
      ...Array.isArray(block.items) ? block.items : []
    ].map(extractItemText).filter((value) => value && !isInvalidLessonObjective(value));
    if (explicit.length) {
      return uniqueText(explicit).map((text) => ({ text, source: "explicit" }));
    }
    const fallbackCandidates = [
      { text: block.successCriteria, source: "successCriteria" },
      { text: block.prompt, source: "prompt" },
      { text: block.scenario, source: "scenario" },
      { text: block.topic, source: "topic" }
    ].map((candidate) => ({
      ...candidate,
      text: cleanText(candidate.text)
    })).filter(
      (candidate) => candidate.text && !isInvalidLessonObjective(candidate.text)
    );
    return fallbackCandidates.length ? [fallbackCandidates[0]] : [];
  }
  var CONCRETE_LABEL_MODES = /* @__PURE__ */ new Set(["vocabulary", "grammar"]);
  var ENGLISH_CURRICULUM_SCAFFOLDING = /\b(?:actions?|adjectives?|agreement|articles?|auxiliary|backchanneling|cause|clauses?|collocations?|comparatives?|compounds?|conditionals?|connectors?|consequence|consonants?|contrast|discourse|endings?|events?|expressions?|field-specific|fillers?|formal|future|gender|gerunds?|idioms?|imperative|imperfect|impersonal|indicative|infinitive|informal|irregulars?|location|markers?|medical|negation|nominalization|nouns?|objects?|opinions?|passive|past|phrases?|plural|possessives?|predictions?|prefixes?|prepositions?|present|preterite|probability|pronouns?|questions?|reflexive|register|regular|repetition|reported|requests?|results?|routines?|singular|stems?|structures?|subjunctive|suffixes?|technical|time|tone|verbs?|voice|word order)\b/i;
  var ENGLISH_CURRICULUM_CONNECTORS = /\b(?:and|as|at|for|from|in|into|of|on|the|to|with|without)\b/i;
  var SPANISH_TARGET_SIGNAL = /[¿¡áéíóúüñ]|\b(?:al|aquí|allí|como|con|cuando|de|del|el|ella|ellos|en|es|esta|este|hay|la|las|lo|los|más|me|mi|no|para|pero|por|que|se|ser|si|sin|son|su|te|tener|tu|un|una|usted|y|yo)\b/i;
  var SUPPORT_GRAMMAR_TERMS = Object.freeze({
    "present perfect": {
      es: "pret\xE9rito perfecto",
      pt: "pret\xE9rito perfeito",
      it: "passato prossimo",
      fr: "pass\xE9 compos\xE9",
      de: "Perfekt",
      ja: "\u73FE\u5728\u5B8C\u4E86\u5F62",
      hi: "\u0935\u0930\u094D\u0924\u092E\u093E\u0928 \u092A\u0942\u0930\u094D\u0923 \u0915\u093E\u0932",
      ar: "\u0627\u0644\u0645\u0636\u0627\u0631\u0639 \u0627\u0644\u062A\u0627\u0645",
      zh: "\u73B0\u5728\u5B8C\u6210\u65F6"
    },
    "past continuous": {
      es: "pasado continuo",
      pt: "passado cont\xEDnuo",
      it: "passato progressivo",
      fr: "pass\xE9 continu",
      de: "Verlaufsform der Vergangenheit",
      ja: "\u904E\u53BB\u9032\u884C\u5F62",
      hi: "\u092D\u0942\u0924\u0915\u093E\u0932 \u0928\u093F\u0930\u0902\u0924\u0930",
      ar: "\u0627\u0644\u0645\u0627\u0636\u064A \u0627\u0644\u0645\u0633\u062A\u0645\u0631",
      zh: "\u8FC7\u53BB\u8FDB\u884C\u65F6"
    },
    "future tense": {
      es: "tiempo futuro",
      pt: "tempo futuro",
      it: "tempo futuro",
      fr: "futur",
      de: "Futur",
      ja: "\u672A\u6765\u5F62",
      hi: "\u092D\u0935\u093F\u0937\u094D\u092F \u0915\u093E\u0932",
      ar: "\u0632\u0645\u0646 \u0627\u0644\u0645\u0633\u062A\u0642\u0628\u0644",
      zh: "\u5C06\u6765\u65F6"
    },
    "past perfect": {
      es: "pluscuamperfecto",
      pt: "mais-que-perfeito",
      it: "trapassato prossimo",
      fr: "plus-que-parfait",
      de: "Plusquamperfekt",
      ja: "\u904E\u53BB\u5B8C\u4E86\u5F62",
      hi: "\u092A\u0942\u0930\u094D\u0923 \u092D\u0942\u0924\u0915\u093E\u0932",
      ar: "\u0627\u0644\u0645\u0627\u0636\u064A \u0627\u0644\u062A\u0627\u0645",
      zh: "\u8FC7\u53BB\u5B8C\u6210\u65F6"
    },
    "passive voice": {
      es: "voz pasiva",
      pt: "voz passiva",
      it: "forma passiva",
      fr: "voix passive",
      de: "Passiv",
      ja: "\u53D7\u52D5\u614B",
      hi: "\u0915\u0930\u094D\u092E\u0935\u093E\u091A\u094D\u092F",
      ar: "\u0627\u0644\u0645\u0628\u0646\u064A \u0644\u0644\u0645\u062C\u0647\u0648\u0644",
      zh: "\u88AB\u52A8\u8BED\u6001"
    },
    "reported speech": {
      es: "estilo indirecto",
      pt: "discurso indireto",
      it: "discorso indiretto",
      fr: "discours indirect",
      de: "indirekte Rede",
      ja: "\u9593\u63A5\u8A71\u6CD5",
      hi: "\u0905\u092A\u094D\u0930\u0924\u094D\u092F\u0915\u094D\u0937 \u0915\u0925\u0928",
      ar: "\u0627\u0644\u0643\u0644\u0627\u0645 \u0627\u0644\u0645\u0646\u0642\u0648\u0644",
      zh: "\u95F4\u63A5\u5F15\u8BED"
    },
    "relative clauses": {
      es: "oraciones de relativo",
      pt: "ora\xE7\xF5es relativas",
      it: "frasi relative",
      fr: "propositions relatives",
      de: "Relativs\xE4tze",
      ja: "\u95A2\u4FC2\u7BC0",
      hi: "\u0938\u0902\u092C\u0902\u0927\u0935\u093E\u091A\u0915 \u0909\u092A\u0935\u093E\u0915\u094D\u092F",
      ar: "\u0627\u0644\u062C\u0645\u0644 \u0627\u0644\u0645\u0648\u0635\u0648\u0644\u0629",
      zh: "\u5173\u7CFB\u4ECE\u53E5"
    },
    "present subjunctive": {
      es: "presente de subjuntivo",
      pt: "presente do subjuntivo",
      it: "congiuntivo presente",
      fr: "subjonctif pr\xE9sent",
      de: "Konjunktiv Pr\xE4sens",
      ja: "\u63A5\u7D9A\u6CD5\u73FE\u5728",
      hi: "\u0935\u0930\u094D\u0924\u092E\u093E\u0928 \u0938\u0902\u092D\u093E\u0935\u0928\u093E\u0930\u094D\u0925\u0915",
      ar: "\u0635\u064A\u063A\u0629 \u0627\u0644\u0634\u0631\u0637 \u0641\u064A \u0627\u0644\u0645\u0636\u0627\u0631\u0639",
      zh: "\u73B0\u5728\u865A\u62DF\u5F0F"
    },
    "past subjunctive": {
      es: "pasado de subjuntivo",
      pt: "pret\xE9rito do subjuntivo",
      it: "congiuntivo passato",
      fr: "subjonctif pass\xE9",
      de: "Konjunktiv Vergangenheit",
      ja: "\u63A5\u7D9A\u6CD5\u904E\u53BB",
      hi: "\u092D\u0942\u0924\u0915\u093E\u0932 \u0938\u0902\u092D\u093E\u0935\u0928\u093E\u0930\u094D\u0925\u0915",
      ar: "\u0635\u064A\u063A\u0629 \u0627\u0644\u0634\u0631\u0637 \u0641\u064A \u0627\u0644\u0645\u0627\u0636\u064A",
      zh: "\u8FC7\u53BB\u865A\u62DF\u5F0F"
    },
    subjunctive: {
      es: "subjuntivo",
      pt: "subjuntivo",
      it: "congiuntivo",
      fr: "subjonctif",
      de: "Konjunktiv",
      ja: "\u63A5\u7D9A\u6CD5",
      hi: "\u0938\u0902\u092D\u093E\u0935\u0928\u093E\u0930\u094D\u0925\u0915",
      ar: "\u0635\u064A\u063A\u0629 \u0627\u0644\u0634\u0631\u0637",
      zh: "\u865A\u62DF\u5F0F"
    },
    infinitive: {
      es: "infinitivo",
      pt: "infinitivo",
      it: "infinito",
      fr: "infinitif",
      de: "Infinitiv",
      ja: "\u4E0D\u5B9A\u8A5E",
      hi: "\u0915\u094D\u0930\u093F\u092F\u093E \u0915\u093E \u092E\u0942\u0932 \u0930\u0942\u092A",
      ar: "\u0627\u0644\u0645\u0635\u062F\u0631",
      zh: "\u4E0D\u5B9A\u5F0F"
    }
  });
  var UNLOCALIZED_CONTEXT_PATTERN = /\b(?:integrated practice|irregular stems|skill builder|word order|introductions?|goodbyes?|present perfect|past continuous|future tense|past perfect|passive voice|reported speech|relative clauses|subjunctive|infinitive)\b/i;
  var hasEnglishCurriculumScaffolding = (value) => ENGLISH_CURRICULUM_SCAFFOLDING.test(value) || ENGLISH_CURRICULUM_CONNECTORS.test(value);
  function localizeEmbeddedGrammarTerms(value, lang) {
    let localized = cleanText(value);
    Object.entries(SUPPORT_GRAMMAR_TERMS).forEach(([englishTerm, translations]) => {
      const replacement = translations[lang];
      if (!replacement) return;
      localized = localized.replace(
        new RegExp(`\\b${englishTerm.replace(/\s+/g, "\\s+")}\\b`, "gi"),
        replacement
      );
    });
    return localized;
  }
  var hasUsableLocalizedContext = (localizedContext, fallbackEn) => !!localizedContext && normalizeObjectiveKey(localizedContext) !== normalizeObjectiveKey(fallbackEn) && !UNLOCALIZED_CONTEXT_PATTERN.test(localizedContext);
  function extractTargetLanguageDetail(value) {
    let detail = cleanText(value).replace(/\bvs\.?\b/gi, "/");
    if (!detail) return "";
    const colonIndex = detail.indexOf(":");
    if (colonIndex > 0) {
      const prefix = detail.slice(0, colonIndex);
      const suffix = cleanText(detail.slice(colonIndex + 1));
      if (suffix && (hasEnglishCurriculumScaffolding(prefix) || SPANISH_TARGET_SIGNAL.test(suffix))) {
        detail = suffix;
      }
    }
    const parentheticalParts = Array.from(
      detail.matchAll(/\(([^()]*)\)/g),
      (match) => cleanText(match[1])
    );
    if (parentheticalParts.length) {
      const outside = cleanText(detail.replace(/\([^()]*\)/g, ""));
      const targetParenthetical = parentheticalParts.find(
        (part) => SPANISH_TARGET_SIGNAL.test(part) && !hasEnglishCurriculumScaffolding(part)
      );
      if (targetParenthetical && hasEnglishCurriculumScaffolding(outside) && !SPANISH_TARGET_SIGNAL.test(outside)) {
        detail = targetParenthetical;
      } else {
        detail = cleanText(
          detail.replace(
            /\(([^()]*)\)/g,
            (match, inner) => hasEnglishCurriculumScaffolding(inner) && !SPANISH_TARGET_SIGNAL.test(inner) ? "" : match
          )
        );
      }
    }
    if (hasEnglishCurriculumScaffolding(detail)) {
      const endings = detail.match(
        /[a-z]*[áéíóúüñ][a-z]*(?:\s*[/,]\s*[a-z]*[áéíóúüñ][a-z]*)+/i
      );
      if (endings) detail = endings[0];
    }
    if (hasEnglishCurriculumScaffolding(detail)) {
      const quotedTargets = Array.from(
        detail.matchAll(/['“‘]([^'”’]+)['”’]/g),
        (match) => cleanText(match[1])
      ).filter(
        (part) => SPANISH_TARGET_SIGNAL.test(part) && !hasEnglishCurriculumScaffolding(part)
      );
      if (quotedTargets.length) detail = uniqueText(quotedTargets).join(" / ");
    }
    return hasEnglishCurriculumScaffolding(detail) ? "" : cleanText(detail);
  }
  function buildObjectiveLabel(mode, objective, lesson) {
    const enPrefix = MODE_LABELS.en[mode] || "Practice";
    const esPrefix = MODE_LABELS.es[mode] || "Practica";
    const objectiveText = cleanText(objective);
    const fallbackEn = getDisplayText(lesson?.description, "en");
    const fallbackEs = getDisplayText(lesson?.description, "es") || fallbackEn;
    const showConcreteEverywhere = !!objectiveText && CONCRETE_LABEL_MODES.has(mode);
    const label = {
      en: objectiveText ? `${enPrefix}: ${objectiveText}` : fallbackEn,
      es: showConcreteEverywhere ? `${esPrefix}: ${objectiveText}` : fallbackEs ? `${esPrefix}: ${fallbackEs}` : esPrefix
    };
    Object.entries(MODE_LABELS).forEach(([lang, labels]) => {
      if (lang === "en" || lang === "es") return;
      const prefix = labels[mode] || labels.realtime;
      if (showConcreteEverywhere) {
        const targetDetail = extractTargetLanguageDetail(objectiveText);
        const localizedContext2 = lesson?.description && typeof lesson.description === "object" ? localizeEmbeddedGrammarTerms(lesson.description[lang], lang) : "";
        const hasLocalizedContext = hasUsableLocalizedContext(
          localizedContext2,
          fallbackEn
        );
        label[lang] = targetDetail ? `${prefix}: ${targetDetail}` : hasLocalizedContext ? `${prefix}: ${localizedContext2}` : prefix;
        return;
      }
      const localizedContext = lesson?.description && typeof lesson.description === "object" ? localizeEmbeddedGrammarTerms(lesson.description[lang], lang) : "";
      if (hasUsableLocalizedContext(localizedContext, fallbackEn)) {
        label[lang] = `${prefix}: ${localizedContext}`;
      } else {
        label[lang] = prefix;
      }
    });
    if (showConcreteEverywhere) {
      const targetDetail = extractTargetLanguageDetail(objectiveText);
      label.es = targetDetail ? `${esPrefix}: ${targetDetail}` : fallbackEs ? `${esPrefix}: ${fallbackEs}` : esPrefix;
    }
    return label;
  }
  function createAgendaItem({ lesson, mode, objective, index, source, block }) {
    const kind = MODE_KIND[mode] || "communication";
    const concept = cleanText(objective);
    const targetRole = EXACT_FORM_MODES.has(mode) && source === "explicit" && !isInstructionalLessonObjective(concept) ? "form" : "goal";
    return normalizeAgendaItemSemantics({
      id: `${mode}-${slugify(concept)}-${index + 1}`,
      kind,
      modes: [mode],
      label: buildObjectiveLabel(mode, concept, lesson),
      goal: concept,
      targetConcept: concept,
      targetRole,
      targetForms: targetRole === "form" ? [concept] : [],
      activityBrief: cleanText(block?.prompt || block?.scenario || ""),
      preserveCanonicalGoal: block?.preserveCanonicalGoal === true,
      targetCurriculumAliases: normalizeTextList(
        block?.targetCurriculumAliases
      ),
      evidence: { ...EVIDENCE_BY_MODE[mode] || EVIDENCE_BY_MODE.realtime },
      source: source || "derived"
    });
  }
  function buildLessonAgenda(lesson, { unit = null } = {}) {
    if (!lesson) return { version: 1, items: [] };
    const modes = Array.isArray(lesson.modes) ? lesson.modes : [];
    const content = lesson.content || {};
    const activeModes = modes.length ? modes : Object.keys(content).filter((mode) => MODE_KIND[mode]);
    const items = [];
    activeModes.forEach((mode) => {
      const block = content[mode];
      if (!block || typeof block !== "object") return;
      const objectives = getConcreteModeObjectives(block);
      objectives.forEach((objective, index) => {
        items.push(
          createAgendaItem({
            lesson,
            mode,
            objective: objective.text,
            index,
            source: objective.source,
            block
          })
        );
      });
    });
    if (!items.length) {
      const fallback = getDisplayText(lesson.description, "en") || getDisplayText(lesson.title, "en") || getDisplayText(unit?.description, "en") || getDisplayText(unit?.title, "en");
      if (fallback && !isInvalidLessonObjective(fallback)) {
        items.push(
          createAgendaItem({
            lesson,
            mode: activeModes[0] || "realtime",
            objective: fallback,
            index: 0,
            source: "lesson-description"
          })
        );
      }
    }
    const usedIds = /* @__PURE__ */ new Map();
    const stableItems = items.map((item) => {
      const count = usedIds.get(item.id) || 0;
      usedIds.set(item.id, count + 1);
      return count ? { ...item, id: `${item.id}-${count + 1}` } : item;
    });
    return { version: 1, items: stableItems };
  }
  function getLessonAgenda(lesson, { unit = null, mode = null, allowLegacy = true, targetLang = "" } = {}) {
    if (!lesson) return [];
    const normalizedTarget = String(targetLang || "").trim().toLowerCase().split(/[-_]/)[0];
    const directManualItems = normalizedTarget === "es" ? getManualSpanishAgendaItems(lesson) : [];
    if (directManualItems.length) {
      return directManualItems.map(normalizeAgendaItemSemantics).filter(
        (item) => !mode || !Array.isArray(item.modes) || item.modes.includes(mode)
      );
    }
    const canonical = Array.isArray(lesson.agenda?.items) ? lesson.agenda.items : [];
    let sourceItems = canonical.length ? canonical : allowLegacy ? buildLessonAgenda(lesson, { unit }).items : [];
    const directFoundationForms = normalizedTarget === "es" ? getManualSpanishFoundationFormItems(lesson) : [];
    if (directFoundationForms.length) {
      sourceItems = [
        ...directFoundationForms,
        ...sourceItems.filter((item) => getAgendaTargetRole(item) !== "form")
      ];
    }
    if (normalizedTarget === "es" && sourceItems.some((item) => item.sourceLessonId)) {
      const replacedSourceIds = /* @__PURE__ */ new Set();
      const expandedFoundationIds = /* @__PURE__ */ new Set();
      sourceItems = sourceItems.flatMap((item) => {
        const sourceLessonId = item.sourceLessonId;
        if (!sourceLessonId) return [item];
        const manualItems = getManualSpanishAgendaItems(sourceLessonId, {
          modes: Array.isArray(item.modes) ? item.modes : lesson.modes
        });
        if (!manualItems.length) {
          const foundationItems = getManualSpanishFoundationFormItems(
            sourceLessonId,
            {
              modes: Array.isArray(item.modes) ? item.modes : ["vocabulary"]
            }
          );
          if (!foundationItems.length || getAgendaTargetRole(item) !== "form") {
            return [item];
          }
          if (expandedFoundationIds.has(sourceLessonId)) return [];
          expandedFoundationIds.add(sourceLessonId);
          return foundationItems.map((foundationItem) => ({
            ...foundationItem,
            id: `review-${sourceLessonId}-${foundationItem.id}`,
            sourceLessonId,
            sourceAgendaItemId: foundationItem.id,
            sourceModes: foundationItem.modes,
            source: "unit-review"
          }));
        }
        if (replacedSourceIds.has(sourceLessonId)) return [];
        replacedSourceIds.add(sourceLessonId);
        return manualItems.map((manualItem) => ({
          ...manualItem,
          id: `review-${sourceLessonId}-${manualItem.id}`,
          sourceLessonId,
          sourceAgendaItemId: manualItem.id,
          sourceModes: manualItem.modes,
          source: "unit-review"
        }));
      });
    }
    const filteredItems = sourceItems.map(normalizeAgendaItemSemantics).filter((item) => {
      const concept = item?.targetConcept || getDisplayText(item?.label, "en");
      if (!item?.id || isInvalidLessonObjective(concept)) return false;
      if (!mode) return true;
      return Array.isArray(item.modes) && item.modes.includes(mode);
    });
    if (!normalizedTarget || normalizedTarget === "es") return filteredItems;
    const adaptedItems = [];
    const groupedItems = /* @__PURE__ */ new Map();
    filteredItems.forEach((item) => {
      const sourceModes = Array.isArray(item.sourceModes) && item.sourceModes.length ? item.sourceModes : item.modes;
      const objectiveMode = sourceModes?.find((candidate) => MODE_KIND[candidate]) || item.modes?.find((candidate) => MODE_KIND[candidate]) || "realtime";
      const sourceLessonId = item.sourceLessonId || lesson.id || "lesson";
      const {
        targetConceptByLanguage,
        targetExamplesByLanguage,
        targetFormsByLanguage,
        ...portableItem
      } = item;
      const authoredTargetConcept = cleanText(
        targetConceptByLanguage?.[normalizedTarget]
      );
      const authoredTargetExamples = Array.isArray(
        targetExamplesByLanguage?.[normalizedTarget]
      ) ? targetExamplesByLanguage[normalizedTarget].map(cleanText).filter(Boolean) : [];
      const authoredTargetForms = normalizeTextList(
        targetFormsByLanguage?.[normalizedTarget]
      );
      if (authoredTargetConcept) {
        const conceptIsShortPhrase = authoredTargetConcept.length <= 32 && authoredTargetConcept.split(/\s+/).length <= 4;
        const targetRole = getAgendaTargetRole(portableItem);
        const targetForms = authoredTargetForms.length ? authoredTargetForms : portableItem.useExamplesAsTargetForms ? authoredTargetExamples : targetRole === "form" ? [authoredTargetConcept] : [];
        const adaptedLabel = Object.fromEntries(
          Object.entries(MODE_LABELS).map(([lang, labels]) => [
            lang,
            `${labels[objectiveMode] || labels.realtime}: ${lang === "en" || conceptIsShortPhrase ? authoredTargetConcept : authoredTargetExamples[0] || authoredTargetConcept}`
          ])
        );
        const label2 = portableItem.preserveCanonicalGoal ? portableItem.label : adaptedLabel;
        adaptedItems.push(normalizeAgendaItemSemantics({
          ...portableItem,
          id: `target-${normalizedTarget}-${item.id}`,
          label: label2,
          goal: portableItem.preserveCanonicalGoal ? portableItem.goal : authoredTargetConcept,
          targetConcept: authoredTargetConcept,
          targetExamples: authoredTargetExamples,
          targetRole,
          targetForms,
          // The pre-adaptation concept is the Spanish-authored base curriculum
          // ("papá" for the English item "dad") — a free support-language gloss
          // for Spanish-support learners of any target language.
          sourceConcept: cleanText(item.targetConcept),
          sourceModes,
          source: "target-language-authored",
          sourceObjectiveSource: portableItem.source || "authored-agenda",
          sourceAgendaItemIds: [item.sourceAgendaItemId || item.id],
          evidence: {
            ...portableItem.evidence || EVIDENCE_BY_MODE[objectiveMode] || EVIDENCE_BY_MODE.realtime
          }
        }));
        return;
      }
      const groupKey = `${sourceLessonId}:${objectiveMode}`;
      const existing = groupedItems.get(groupKey);
      if (existing) {
        existing.sourceAgendaItemIds.push(item.sourceAgendaItemId || item.id);
        return;
      }
      const sourceLesson = unit?.lessons?.find((candidate) => candidate?.id === sourceLessonId) || lesson;
      const sourceTitle = item.sourceLessonTitle || sourceLesson.title || lesson.title;
      const skillTitle = unit?.title || sourceTitle;
      const skillTitleEn = getDisplayText(skillTitle, "en") || getDisplayText(sourceTitle, "en") || "this lesson";
      const sourceTitleEn = getDisplayText(sourceTitle, "en") || skillTitleEn;
      const sourceBlock = sourceLesson?.content?.[objectiveMode] || {};
      const rawContextEn = cleanText(
        sourceBlock.scenario || sourceBlock.topic || sourceBlock.successCriteria || ""
      );
      const contextLooksTargetSpecific = /[¿¡]|\b(?:vos|vosotros|usted|ustedes|tú|ser|estar|haber|había|se\s+(?:hace|vende|venden)|por\s+qué)\b/i.test(
        rawContextEn
      );
      const contextEn = contextLooksTargetSpecific ? "" : rawContextEn;
      const capitalizedContext = contextEn ? `${contextEn.charAt(0).toUpperCase()}${contextEn.slice(1)}` : "";
      const detailEn = capitalizedContext ? `${skillTitleEn} \u2014 ${capitalizedContext}` : skillTitleEn === sourceTitleEn ? skillTitleEn : `${skillTitleEn} \u2014 ${sourceTitleEn}`;
      const label = Object.fromEntries(
        Object.entries(MODE_LABELS).map(([lang, labels]) => {
          const localizedSkill = getDisplayText(skillTitle, lang) || skillTitleEn;
          const localizedLesson = getDisplayText(sourceTitle, lang) || sourceTitleEn;
          const localizedDetail = lang === "en" ? detailEn : localizedSkill === localizedLesson ? localizedSkill : `${localizedSkill} \u2014 ${localizedLesson}`;
          return [
            lang,
            `${labels[objectiveMode] || labels.realtime}: ${localizedDetail}`
          ];
        })
      );
      const groupEntry = normalizeAgendaItemSemantics({
        ...portableItem,
        id: `target-${normalizedTarget}-${sourceLessonId}-${objectiveMode}`,
        label,
        goal: `${label.en}. Complete this objective in the selected practice language.`,
        targetConcept: `${label.en}. Complete this objective in the selected practice language.`,
        targetExamples: [],
        targetRole: "goal",
        targetForms: [],
        sourceModes,
        source: "target-language-adapter",
        sourceObjectiveSource: portableItem.source || "unknown",
        sourceAgendaItemIds: [item.sourceAgendaItemId || item.id],
        evidence: {
          ...EVIDENCE_BY_MODE[objectiveMode] || EVIDENCE_BY_MODE.realtime
        }
      });
      groupedItems.set(groupKey, groupEntry);
      adaptedItems.push(groupEntry);
    });
    return adaptedItems;
  }
  function buildUnitCurriculumSnapshot(unit, { beforeLessonId = "", includeLessonIds = [], targetLang = "" } = {}) {
    const lessons = Array.isArray(unit?.lessons) ? unit.lessons : [];
    const explicitIds = new Set(includeLessonIds);
    const sourceLessons = [];
    for (const lesson of lessons) {
      if (beforeLessonId && lesson?.id === beforeLessonId) break;
      if (!lesson || isReviewLesson(lesson)) continue;
      if (explicitIds.size && !explicitIds.has(lesson.id)) continue;
      sourceLessons.push(lesson);
    }
    const agendaItems = sourceLessons.flatMap(
      (lesson) => getLessonAgenda(lesson, { unit, targetLang }).map((item) => ({
        ...item,
        sourceLessonId: lesson.id,
        sourceLessonTitle: lesson.title
      }))
    );
    const byKind = (kind) => agendaItems.filter((item) => item.kind === kind).map((item) => item.id);
    return {
      version: 1,
      unitId: unit?.id || "",
      unitTitle: unit?.title || null,
      cefrLevel: unit?.cefrLevel || unit?.level || "",
      sourceLessonIds: sourceLessons.map((lesson) => lesson.id),
      agendaItems,
      vocabularyItemIds: byKind("vocabulary"),
      grammarItemIds: byKind("grammar"),
      comprehensionItemIds: byKind("comprehension"),
      communicationItemIds: byKind("communication")
    };
  }
  function buildUnitQuizBlueprint(unit, { beforeLessonId = "", questionCount = 10, targetLang = "" } = {}) {
    const snapshot = buildUnitCurriculumSnapshot(unit, {
      beforeLessonId,
      targetLang
    });
    const safeQuestionCount = Math.max(1, Math.floor(Number(questionCount) || 10));
    const lessonQueues = snapshot.sourceLessonIds.map((lessonId) => ({
      lessonId,
      items: snapshot.agendaItems.filter(
        (item) => item.sourceLessonId === lessonId
      )
    })).filter((queue) => queue.items.length);
    const selected = [];
    while (selected.length < safeQuestionCount) {
      let addedInRound = false;
      for (const queue of lessonQueues) {
        if (!queue.items.length || selected.length >= safeQuestionCount) continue;
        const usedKinds = new Set(selected.map((item) => item.kind));
        const preferredIndex = queue.items.findIndex(
          (item) => !usedKinds.has(item.kind)
        );
        const [nextItem] = queue.items.splice(
          preferredIndex >= 0 ? preferredIndex : 0,
          1
        );
        selected.push(nextItem);
        addedInRound = true;
      }
      if (!addedInRound) break;
    }
    return {
      version: 1,
      questionCount: selected.length,
      sourceLessonIds: Array.from(
        new Set(selected.map((item) => item.sourceLessonId))
      ),
      questionTargets: selected.map((item, index) => ({
        questionNumber: index + 1,
        agendaItemId: item.sourceAgendaItemId || item.id,
        sourceLessonId: item.sourceLessonId,
        kind: item.kind,
        modes: item.modes,
        targetRole: getAgendaTargetRole(item),
        targetForms: getAgendaTargetForms(item),
        goal: getAgendaGoal(item),
        targetConcept: item.targetConcept,
        sourceConcept: item.sourceConcept,
        labels: item.labels,
        activityBrief: item.activityBrief,
        targetExamples: Array.isArray(item.targetExamples) ? item.targetExamples : [],
        evidence: item.evidence
      }))
    };
  }
  var INVALID_LESSON_OBJECTIVE_LABELS = Object.freeze([
    ...INVALID_OBJECTIVE_LABELS
  ]);

  // ../nosabos/nosabos/src/utils/gameReviewContext.js
  function cleanString(value) {
    return String(value || "").trim();
  }
  function uniqueStrings(values = []) {
    return Array.from(
      new Set(values.map(cleanString).filter(Boolean))
    );
  }
  function inferCefrLevelFromLessonId(lessonId = "") {
    const id = cleanString(lessonId).toLowerCase();
    if (!id) return null;
    if (id.includes("lesson-tutorial") || id.includes("lesson-pre-a1")) {
      return "Pre-A1";
    }
    const match = id.match(/lesson-([a-z]\d+)/i);
    return match ? match[1].toUpperCase() : null;
  }
  function getLocalizedText(value, locale = "en") {
    if (typeof value === "string") return cleanString(value);
    if (!value || typeof value !== "object") return "";
    return cleanString(value[locale] || value.en || value.es || "");
  }
  function collectModeTerms(modeData = {}) {
    if (!modeData || typeof modeData !== "object") return [];
    return uniqueStrings([
      ...Array.isArray(modeData.focusPoints) ? modeData.focusPoints : [],
      ...Array.isArray(modeData.topics) ? modeData.topics : [],
      ...Array.isArray(modeData.unitTopics) ? modeData.unitTopics : [],
      modeData.tutorialPracticeLevel && modeData.topic === "tutorial" ? "" : modeData.topic,
      modeData.scenario,
      modeData.unitTitle
    ]);
  }
  function collectModeObjectives(modeData = {}) {
    if (!modeData || typeof modeData !== "object") return [];
    return uniqueStrings([
      modeData.prompt,
      modeData.scenario,
      modeData.successCriteria,
      modeData.tutorialDescription?.en
    ]);
  }
  function collectRelevantLessons(lesson, unit) {
    const unitLessons = Array.isArray(unit?.lessons) ? unit.lessons : [];
    if (lesson?.isTutorial) return [lesson].filter(Boolean);
    if (isReviewLesson(lesson) && unitLessons.length) {
      const relevant = [];
      for (const entry of unitLessons) {
        if (entry?.id === lesson?.id) break;
        if (entry && !isReviewLesson(entry)) relevant.push(entry);
      }
      return relevant;
    }
    return [lesson].filter(Boolean);
  }
  function buildReviewLesson(entry) {
    const modes = Object.entries(entry?.content || {}).filter(([, modeData]) => modeData && typeof modeData === "object").map(([mode, modeData]) => ({
      mode,
      topic: cleanString(modeData.topic || modeData.scenario),
      focusPoints: uniqueStrings([
        ...Array.isArray(modeData.focusPoints) ? modeData.focusPoints : [],
        ...Array.isArray(modeData.topics) ? modeData.topics : []
      ]),
      prompt: cleanString(modeData.prompt),
      successCriteria: cleanString(modeData.successCriteria)
    })).filter(
      (mode) => mode.topic || mode.focusPoints.length || mode.prompt || mode.successCriteria
    );
    return {
      id: entry?.id || "",
      title: getLocalizedText(entry?.title, "en"),
      description: getLocalizedText(entry?.description, "en"),
      modes
    };
  }
  function buildGameReviewContext({
    lesson,
    unit = null,
    fallbackLevel = null,
    targetLang = ""
  }) {
    if (!lesson) return null;
    const normalizedTargetLang = cleanString(targetLang).toLowerCase().split(/[-_]/)[0];
    const usesTargetLanguageAdapter = !!normalizedTargetLang && normalizedTargetLang !== "es" && !lesson?.tutorialPracticeLevel;
    const relevantLessons = collectRelevantLessons(lesson, unit);
    const curriculumSnapshot = isReviewLesson(lesson) ? buildUnitCurriculumSnapshot(unit, {
      beforeLessonId: lesson.id,
      targetLang
    }) : {
      version: 1,
      unitId: unit?.id || "",
      unitTitle: unit?.title || null,
      sourceLessonIds: lesson?.id ? [lesson.id] : [],
      agendaItems: getLessonAgenda(lesson, { unit, targetLang }).map((item) => ({
        ...item,
        sourceLessonId: lesson.id,
        sourceLessonTitle: lesson.title
      }))
    };
    const quizBlueprint = lesson?.isFinalQuiz ? buildUnitQuizBlueprint(unit, {
      beforeLessonId: lesson.id,
      questionCount: lesson?.quizConfig?.questionCount || lesson?.quizConfig?.questionsRequired || 10,
      targetLang
    }) : null;
    const reviewLessons = relevantLessons.map(buildReviewLesson);
    const lessonTitles = uniqueStrings(
      relevantLessons.map((entry) => getLocalizedText(entry?.title, "en"))
    );
    const reviewTerms = uniqueStrings(
      relevantLessons.flatMap(
        (entry) => Object.values(entry?.content || {}).filter((modeData) => modeData && typeof modeData === "object").flatMap((modeData) => collectModeTerms(modeData))
      )
    );
    const reviewObjectives = uniqueStrings(
      relevantLessons.flatMap(
        (entry) => Object.values(entry?.content || {}).filter((modeData) => modeData && typeof modeData === "object").flatMap((modeData) => collectModeObjectives(modeData))
      )
    );
    const cefrLevel = lesson?.content?.game?.cefrLevel || unit?.cefrLevel || fallbackLevel || inferCefrLevelFromLessonId(lesson.id) || "Pre-A1";
    const unitTitle = getLocalizedText(unit?.title, "en") || lesson?.content?.game?.unitTitle || "";
    const lessonTitle = getLocalizedText(lesson?.title, "en");
    const tutorialTerms = lesson?.isTutorial && !lesson?.tutorialPracticeLevel ? ["hello", "hi", "good morning", "goodbye", "my name is"] : [];
    const finalTerms = uniqueStrings([
      ...tutorialTerms,
      ...reviewTerms,
      ...Array.isArray(lesson?.content?.game?.focusPoints) ? lesson.content.game.focusPoints : [],
      lesson?.tutorialPracticeLevel ? "" : lesson?.content?.game?.topic,
      lesson?.content?.game?.unitTitle,
      unitTitle,
      lessonTitle
    ]).slice(0, 40);
    const mode = lesson?.isTutorial ? "tutorial" : lesson?.isGame ? "unit_review" : "lesson_review";
    const curriculumSummary = lesson?.isTutorial ? lesson?.tutorialPracticeLevel ? `Tutorial review at CEFR ${lesson.tutorialPracticeLevel}. Introduce the game interaction using ${lesson?.content?.game?.focusPoints?.[0]}. Keep the language appropriate to this level.` : "Tutorial review. Keep the game limited to greetings, saying your name, and very simple polite responses." : lesson?.isGame ? `Unit review for ${unitTitle || lessonTitle}. Recycle the key language from this chapter only.` : `Review the active lesson ${lessonTitle} using nearby chapter topics and the current proficiency level.`;
    return {
      mode,
      isTutorial: !!lesson?.isTutorial,
      tutorialPracticeLevel: lesson?.tutorialPracticeLevel || null,
      isGameReview: !!lesson?.isGame,
      cefrLevel,
      unitId: unit?.id || "",
      unitTitle,
      lessonId: lesson?.id || "",
      lessonTitle,
      lessonTitles,
      targetLang: normalizedTargetLang,
      targetLanguageAdapted: usesTargetLanguageAdapter,
      reviewLessons: usesTargetLanguageAdapter ? reviewLessons.map((entry) => ({
        ...entry,
        modes: entry.modes.map((mode2) => ({
          mode: mode2.mode,
          topic: entry.title,
          focusPoints: [],
          prompt: `Practice ${entry.title} in the selected practice language`,
          successCriteria: "Demonstrates the lesson objective in context"
        }))
      })) : reviewLessons,
      sourceLessonIds: curriculumSnapshot.sourceLessonIds,
      agendaItems: curriculumSnapshot.agendaItems,
      reviewStrategy: lesson?.reviewStrategy || null,
      quizBlueprint,
      reviewTerms: usesTargetLanguageAdapter ? uniqueStrings([...lessonTitles, unitTitle, lessonTitle]) : finalTerms,
      reviewObjectives: usesTargetLanguageAdapter ? uniqueStrings(
        curriculumSnapshot.agendaItems.map((item) => item.targetConcept)
      ).slice(0, 16) : reviewObjectives.slice(0, 16),
      curriculumSummary
    };
  }

  // flags:flags
  var brazilianFlag = () => null;
  var chineseFlag = () => null;
  var egyptianFlag = () => null;
  var frenchFlag = () => null;
  var germanFlag = () => null;
  var greekFlag = () => null;
  var indianFlag = () => null;
  var irishFlag = () => null;
  var italianFlag = () => null;
  var japaneseFlag = () => null;
  var mexicanFlag = () => null;
  var netherlandsFlag = () => null;
  var polishFlag = () => null;
  var russianFlag = () => null;
  var usaFlag = () => null;

  // ../nosabos/nosabos/src/constants/supportLanguages.js
  var SUPPORT_LANGUAGE_CODES = Object.freeze([
    "en",
    "es",
    "pt",
    "it",
    "fr",
    "de",
    "ja",
    "hi",
    "ar",
    "zh"
  ]);

  // ../nosabos/nosabos/src/constants/languages.js
  var DEFAULT_SUPPORT_LANGUAGE = "en";
  var LANGUAGE_FALLBACK_LABELS = {
    ar: "Egyptian Arabic",
    zh: "Mandarin Chinese",
    en: "English",
    es: "Spanish",
    pt: "Portuguese",
    fr: "French",
    it: "Italian",
    hi: "Hindi",
    nl: "Dutch",
    nah: "Eastern Huasteca Nahuatl",
    ja: "Japanese (\u65E5\u672C\u8A9E)",
    ru: "Russian",
    de: "German",
    el: "Greek",
    pl: "Polish",
    ga: "Irish",
    yua: "Yucatec Maya"
  };
  var LANGUAGE_PROMPT_LABELS = {
    ar: "Egyptian Arabic (\u0627\u0644\u0639\u0631\u0628\u064A\u0629 \u0627\u0644\u0645\u0635\u0631\u064A\u0629)",
    zh: "Mandarin Chinese (\u666E\u901A\u8BDD\u4E2D\u6587)",
    es: "Spanish (espanol)",
    en: "English",
    pt: "Portuguese (portugues brasileiro)",
    fr: "French (francais)",
    it: "Italian (italiano)",
    hi: "Hindi (hindi)",
    nl: "Dutch (Nederlands)",
    nah: "Eastern Huasteca Nahuatl (nahuatl huasteco oriental)",
    ru: "Russian",
    de: "German (Deutsch)",
    el: "Greek",
    pl: "Polish (polski)",
    ga: "Irish (Gaeilge)",
    yua: "Yucatec Maya (maaya t'aan)",
    ja: "Japanese (\u65E5\u672C\u8A9E)"
  };
  var LANGUAGE_META = [
    {
      value: "ar",
      languageKey: "language_ar",
      practiceKey: "onboarding_practice_ar",
      tier: "stable",
      supportTier: "stable",
      practiceEnabled: false,
      flag: egyptianFlag
    },
    {
      value: "nl",
      languageKey: "language_nl",
      practiceKey: "onboarding_practice_nl",
      tier: "stable",
      flag: netherlandsFlag
    },
    {
      value: "en",
      languageKey: "language_en",
      practiceKey: "onboarding_practice_en",
      tier: "stable",
      flag: usaFlag
    },
    {
      value: "fr",
      languageKey: "language_fr",
      practiceKey: "onboarding_practice_fr",
      tier: "stable",
      flag: frenchFlag
    },
    {
      value: "de",
      languageKey: "language_de",
      practiceKey: "onboarding_practice_de",
      tier: "stable",
      flag: germanFlag
    },
    {
      value: "it",
      languageKey: "language_it",
      practiceKey: "onboarding_practice_it",
      tier: "stable",
      flag: italianFlag
    },
    {
      value: "hi",
      languageKey: "language_hi",
      practiceKey: "onboarding_practice_hi",
      tier: "stable",
      supportTier: "stable",
      practiceEnabled: false,
      flag: indianFlag
    },
    {
      value: "zh",
      languageKey: "language_zh",
      practiceKey: "onboarding_practice_zh",
      tier: "stable",
      supportTier: "stable",
      practiceEnabled: false,
      flag: chineseFlag
    },
    {
      value: "pt",
      languageKey: "language_pt",
      practiceKey: "onboarding_practice_pt",
      tier: "stable",
      flag: brazilianFlag
    },
    {
      value: "es",
      languageKey: "language_es",
      practiceKey: "onboarding_practice_es",
      tier: "stable",
      flag: mexicanFlag
    },
    {
      value: "nah",
      languageKey: "language_nah",
      practiceKey: "onboarding_practice_nah",
      tier: "alpha",
      // Temporarily hidden from practice-language selectors. Keep the language
      // registered so existing user data and the underlying implementation work.
      selectorHidden: true,
      flag: mexicanFlag
    },
    {
      value: "yua",
      languageKey: "language_yua",
      practiceKey: "onboarding_practice_yua",
      tier: "alpha",
      // Temporarily hidden from practice-language selectors. Keep the language
      // registered so existing user data and the underlying implementation work.
      selectorHidden: true,
      flag: mexicanFlag
    },
    {
      value: "el",
      languageKey: "language_el",
      practiceKey: "onboarding_practice_el",
      tier: "beta",
      flag: greekFlag
    },
    {
      value: "ja",
      languageKey: "language_ja",
      practiceKey: "onboarding_practice_ja",
      tier: "beta",
      supportTier: "stable",
      flag: japaneseFlag
    },
    {
      value: "ru",
      languageKey: "language_ru",
      practiceKey: "onboarding_practice_ru",
      tier: "beta",
      flag: russianFlag
    },
    {
      value: "pl",
      languageKey: "language_pl",
      practiceKey: "onboarding_practice_pl",
      tier: "beta",
      flag: polishFlag
    },
    {
      value: "ga",
      languageKey: "language_ga",
      practiceKey: "onboarding_practice_ga",
      tier: "beta",
      flag: irishFlag
    }
  ];
  var SUPPORTED_LANGUAGE_CODES_SET = new Set(
    LANGUAGE_META.map((item) => item.value)
  );
  var PRACTICE_LANGUAGE_CODES_BASE = LANGUAGE_META.filter(
    (item) => item.practiceEnabled !== false
  ).map((item) => item.value);
  var PRACTICE_LANGUAGE_CODES_SET = new Set(PRACTICE_LANGUAGE_CODES_BASE);
  var SUPPORT_LANGUAGE_CODES_BASE = [...SUPPORT_LANGUAGE_CODES];
  var SUPPORT_LANGUAGE_CODES_SET = new Set(SUPPORT_LANGUAGE_CODES_BASE);
  var normalizeCode = (raw) => String(raw || "").trim().toLowerCase();
  var normalizeSupportedCode = (raw) => {
    const normalized = normalizeCode(raw);
    if (!normalized) return "";
    if (normalized === "arz") return "ar";
    if (normalized === "cmn") return "zh";
    if (SUPPORTED_LANGUAGE_CODES_SET.has(normalized)) return normalized;
    const [base] = normalized.split(/[-_]/);
    if (base === "arz" && SUPPORTED_LANGUAGE_CODES_SET.has("ar")) return "ar";
    if (base === "cmn" && SUPPORTED_LANGUAGE_CODES_SET.has("zh")) return "zh";
    if (SUPPORTED_LANGUAGE_CODES_SET.has(base)) return base;
    return normalized;
  };
  var PRACTICE_LANGUAGE_CODES = [...PRACTICE_LANGUAGE_CODES_BASE];
  var SUPPORT_LANGUAGE_CODES2 = SUPPORT_LANGUAGE_CODES_BASE.filter(
    (code) => SUPPORTED_LANGUAGE_CODES_SET.has(code)
  );
  var ALPHABET_LANGUAGE_CODES = [...PRACTICE_LANGUAGE_CODES];
  function normalizeSupportLanguage(code, fallback = DEFAULT_SUPPORT_LANGUAGE) {
    const normalized = normalizeSupportedCode(code);
    if (SUPPORT_LANGUAGE_CODES_SET.has(normalized)) return normalized;
    return fallback;
  }
  function getLanguagePromptName(code) {
    const normalized = normalizeSupportedCode(code);
    if (!normalized) return "";
    return LANGUAGE_PROMPT_LABELS[normalized] || LANGUAGE_FALLBACK_LABELS[normalized] || normalized.toUpperCase();
  }

  // ../nosabos/nosabos/src/data/flashcards/japaneseLocalizer.js
  var EXACT_TRANSLATIONS = {
    hello: "\u3053\u3093\u306B\u3061\u306F",
    hi: "\u3084\u3042",
    goodbye: "\u3055\u3088\u3046\u306A\u3089",
    bye: "\u3058\u3083\u3042\u306D",
    please: "\u304A\u9858\u3044\u3057\u307E\u3059",
    "thank you": "\u3042\u308A\u304C\u3068\u3046",
    "you're welcome": "\u3069\u3046\u3044\u305F\u3057\u307E\u3057\u3066",
    "excuse me": "\u3059\u307F\u307E\u305B\u3093",
    sorry: "\u3054\u3081\u3093\u306A\u3055\u3044",
    "i'm sorry": "\u3059\u307F\u307E\u305B\u3093",
    yes: "\u306F\u3044",
    no: "\u3044\u3044\u3048",
    maybe: "\u305F\u3076\u3093",
    okay: "\u5927\u4E08\u592B",
    "how are you?": "\u5143\u6C17\u3067\u3059\u304B\uFF1F",
    "nice to meet you": "\u306F\u3058\u3081\u307E\u3057\u3066",
    "have a good day": "\u3088\u3044\u4E00\u65E5\u3092",
    "see you later": "\u307E\u305F\u5F8C\u3067",
    "see you soon": "\u307E\u305F\u3059\u3050\u306B",
    "see you tomorrow": "\u307E\u305F\u660E\u65E5",
    "good morning": "\u304A\u306F\u3088\u3046\u3054\u3056\u3044\u307E\u3059",
    "good afternoon": "\u3053\u3093\u306B\u3061\u306F",
    "good evening": "\u3053\u3093\u3070\u3093\u306F",
    "good night": "\u304A\u3084\u3059\u307F\u306A\u3055\u3044",
    "how's it going?": "\u8ABF\u5B50\u306F\u3069\u3046\u3067\u3059\u304B\uFF1F",
    "what's up?": "\u3069\u3046\u3057\u305F\u306E\uFF1F",
    "bless you": "\u304A\u5927\u4E8B\u306B",
    congratulations: "\u304A\u3081\u3067\u3068\u3046",
    "happy birthday": "\u304A\u8A95\u751F\u65E5\u304A\u3081\u3067\u3068\u3046",
    "merry christmas": "\u30E1\u30EA\u30FC\u30AF\u30EA\u30B9\u30DE\u30B9",
    "happy new year": "\u3042\u3051\u307E\u3057\u3066\u304A\u3081\u3067\u3068\u3046",
    welcome: "\u3088\u3046\u3053\u305D",
    pardon: "\u5931\u793C",
    "my name is...": "\u79C1\u306E\u540D\u524D\u306F\u2026\u3067\u3059",
    "i'm from...": "\u79C1\u306F\u2026\u51FA\u8EAB\u3067\u3059",
    "i'm x years old": "\u79C1\u306F\u301C\u6B73\u3067\u3059",
    "what's your name?": "\u304A\u540D\u524D\u306F\u4F55\u3067\u3059\u304B\uFF1F",
    "where are you from?": "\u3069\u3053\u306E\u51FA\u8EAB\u3067\u3059\u304B\uFF1F",
    "how old are you?": "\u304A\u3044\u304F\u3064\u3067\u3059\u304B\uFF1F",
    "this is my friend...": "\u3053\u3061\u3089\u306F\u79C1\u306E\u53CB\u3060\u3061\u3067\u3059\u2026",
    "i live in...": "\u79C1\u306F\u2026\u306B\u4F4F\u3093\u3067\u3044\u307E\u3059",
    "i speak...": "\u79C1\u306F\u2026\u3092\u8A71\u3057\u307E\u3059",
    "do you speak english?": "\u82F1\u8A9E\u3092\u8A71\u305B\u307E\u3059\u304B\uFF1F",
    "how much?": "\u3044\u304F\u3089\u3067\u3059\u304B\uFF1F",
    "too expensive": "\u9AD8\u3059\u304E\u307E\u3059",
    "one more": "\u3082\u3046\u4E00\u3064",
    "two, please": "\u4E8C\u3064\u304A\u9858\u3044\u3057\u307E\u3059",
    today: "\u4ECA\u65E5",
    tomorrow: "\u660E\u65E5",
    yesterday: "\u6628\u65E5",
    now: "\u4ECA",
    later: "\u5F8C\u3067",
    "what time is it?": "\u4ECA\u4F55\u6642\u3067\u3059\u304B\uFF1F",
    "at what time?": "\u4F55\u6642\u306B\uFF1F",
    "what day is today?": "\u4ECA\u65E5\u306F\u4F55\u66DC\u65E5\u3067\u3059\u304B\uFF1F",
    "when?": "\u3044\u3064\uFF1F",
    "in the morning": "\u671D\u306B",
    "in the afternoon": "\u5348\u5F8C\u306B",
    "at night": "\u591C\u306B",
    "what is this?": "\u3053\u308C\u306F\u4F55\u3067\u3059\u304B\uFF1F",
    "where is...?": "\u2026\u306F\u3069\u3053\u3067\u3059\u304B\uFF1F",
    "when does it open?": "\u3044\u3064\u958B\u304D\u307E\u3059\u304B\uFF1F",
    "who is that?": "\u3042\u308C\u306F\u8AB0\u3067\u3059\u304B\uFF1F",
    "why?": "\u306A\u305C\uFF1F",
    "how do i get to...?": "\u2026\u3078\u306F\u3069\u3046\u884C\u304D\u307E\u3059\u304B\uFF1F",
    "how much does it cost?": "\u3044\u304F\u3089\u304B\u304B\u308A\u307E\u3059\u304B\uFF1F",
    "how long?": "\u3069\u308C\u304F\u3089\u3044\u3067\u3059\u304B\uFF1F",
    "how far?": "\u3069\u308C\u304F\u3089\u3044\u9060\u3044\u3067\u3059\u304B\uFF1F",
    "can you help me?": "\u624B\u4F1D\u3063\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "can i...?": "\u2026\u3057\u3066\u3082\u3044\u3044\u3067\u3059\u304B\uFF1F",
    "is there...?": "\u2026\u306F\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "do you have...?": "\u2026\u306F\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "i would like...": "\u2026\u3092\u304A\u9858\u3044\u3057\u307E\u3059",
    "i'm hungry": "\u304A\u8179\u304C\u7A7A\u304D\u307E\u3057\u305F",
    "i'm thirsty": "\u5589\u304C\u6E07\u304D\u307E\u3057\u305F",
    "the check, please": "\u304A\u4F1A\u8A08\u3092\u304A\u9858\u3044\u3057\u307E\u3059",
    "a table for two": "\u4E8C\u4EBA\u7528\u306E\u5E2D\u3092\u304A\u9858\u3044\u3057\u307E\u3059",
    "menu, please": "\u30E1\u30CB\u30E5\u30FC\u3092\u304A\u9858\u3044\u3057\u307E\u3059",
    "cheers!": "\u4E7E\u676F\uFF01",
    "enjoy your meal": "\u3069\u3046\u305E\u53EC\u3057\u4E0A\u304C\u308C",
    "it's delicious": "\u304A\u3044\u3057\u3044\u3067\u3059",
    "no ice, please": "\u6C37\u306A\u3057\u3067\u304A\u9858\u3044\u3057\u307E\u3059",
    "to go": "\u6301\u3061\u5E30\u308A",
    vegetarian: "\u30D9\u30B8\u30BF\u30EA\u30A2\u30F3",
    "gluten-free": "\u30B0\u30EB\u30C6\u30F3\u30D5\u30EA\u30FC",
    spicy: "\u8F9B\u3044",
    "without...": "\u2026\u629C\u304D\u3067",
    "more bread, please": "\u30D1\u30F3\u3092\u3082\u3046\u5C11\u3057\u304A\u9858\u3044\u3057\u307E\u3059",
    "water, please": "\u304A\u6C34\u3092\u304A\u9858\u3044\u3057\u307E\u3059",
    "where is the bathroom?": "\u304A\u624B\u6D17\u3044\u306F\u3069\u3053\u3067\u3059\u304B\uFF1F",
    "turn left": "\u5DE6\u306B\u66F2\u304C\u3063\u3066\u304F\u3060\u3055\u3044",
    "turn right": "\u53F3\u306B\u66F2\u304C\u3063\u3066\u304F\u3060\u3055\u3044",
    "go straight": "\u307E\u3063\u3059\u3050\u9032\u3093\u3067\u304F\u3060\u3055\u3044",
    "it's near": "\u8FD1\u3044\u3067\u3059",
    "it's far": "\u9060\u3044\u3067\u3059",
    "stop here, please": "\u3053\u3053\u3067\u6B62\u3081\u3066\u304F\u3060\u3055\u3044",
    "take me to...": "\u2026\u307E\u3067\u304A\u9858\u3044\u3057\u307E\u3059",
    "how much to...?": "\u2026\u307E\u3067\u3044\u304F\u3089\u3067\u3059\u304B\uFF1F",
    "one ticket, please": "\u5207\u7B26\u3092\u4E00\u679A\u304A\u9858\u3044\u3057\u307E\u3059",
    "what time does it leave?": "\u4F55\u6642\u306B\u51FA\u767A\u3057\u307E\u3059\u304B\uFF1F",
    "i'll take it": "\u3053\u308C\u306B\u3057\u307E\u3059",
    "do you accept credit cards?": "\u30AF\u30EC\u30B8\u30C3\u30C8\u30AB\u30FC\u30C9\u306F\u4F7F\u3048\u307E\u3059\u304B\uFF1F",
    "can i pay with...?": "\u2026\u3067\u652F\u6255\u3048\u307E\u3059\u304B\uFF1F",
    "is there a discount?": "\u5272\u5F15\u306F\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "just looking": "\u898B\u3066\u3044\u308B\u3060\u3051\u3067\u3059",
    "what size?": "\u3069\u306E\u30B5\u30A4\u30BA\u3067\u3059\u304B\uFF1F",
    "do you have this in another color?": "\u3053\u308C\u306E\u5225\u306E\u8272\u306F\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "can i try it on?": "\u8A66\u7740\u3057\u3066\u3082\u3044\u3044\u3067\u3059\u304B\uFF1F",
    "where is the fitting room?": "\u8A66\u7740\u5BA4\u306F\u3069\u3053\u3067\u3059\u304B\uFF1F",
    "i'm looking for...": "\u2026\u3092\u63A2\u3057\u3066\u3044\u307E\u3059",
    "that's too small": "\u305D\u308C\u306F\u5C0F\u3055\u3059\u304E\u307E\u3059",
    "that's too big": "\u305D\u308C\u306F\u5927\u304D\u3059\u304E\u307E\u3059",
    "it fits well": "\u3061\u3087\u3046\u3069\u3044\u3044\u3067\u3059",
    "can you lower the price?": "\u3082\u3046\u5C11\u3057\u5B89\u304F\u3067\u304D\u307E\u3059\u304B\uFF1F",
    "i don't know": "\u308F\u304B\u308A\u307E\u305B\u3093",
    "i understand": "\u308F\u304B\u308A\u307E\u3059",
    "i don't understand": "\u308F\u304B\u308A\u307E\u305B\u3093",
    "let me think": "\u5C11\u3057\u8003\u3048\u3055\u305B\u3066\u304F\u3060\u3055\u3044",
    "where there's smoke, there's fire": "\u706B\u306E\u306A\u3044\u3068\u3053\u308D\u306B\u7159\u306F\u7ACB\u305F\u306C",
    "the grass is always greener on the other side": "\u96A3\u306E\u829D\u751F\u306F\u9752\u304F\u898B\u3048\u308B",
    "don't put all your eggs in one basket": "\u4E00\u3064\u306E\u304B\u3054\u306B\u3059\u3079\u3066\u306E\u5375\u3092\u5165\u308C\u308B\u306A",
    "a picture is worth a thousand words": "\u767E\u805E\u306F\u4E00\u898B\u306B\u3057\u304B\u305A",
    "rome wasn't built in a day": "\u30ED\u30FC\u30DE\u306F\u4E00\u65E5\u306B\u3057\u3066\u6210\u3089\u305A",
    "the pen is mightier than the sword": "\u30DA\u30F3\u306F\u5263\u3088\u308A\u3082\u5F37\u3057",
    "you can't judge a book by its cover": "\u898B\u304B\u3051\u3067\u5224\u65AD\u3057\u3066\u306F\u3044\u3051\u306A\u3044",
    "two heads are better than one": "\u4E09\u4EBA\u5BC4\u308C\u3070\u6587\u6B8A\u306E\u77E5\u6075",
    "time heals all wounds": "\u6642\u304C\u3059\u3079\u3066\u306E\u50B7\u3092\u7652\u3059",
    "honesty is the best policy": "\u6B63\u76F4\u306F\u6700\u5584\u306E\u7B56",
    "practice makes perfect": "\u7FD2\u3046\u3088\u308A\u6163\u308C\u308D",
    "good things come to those who wait": "\u5F85\u3066\u3070\u6D77\u8DEF\u306E\u65E5\u548C\u3042\u308A",
    "all's fair in love and war": "\u604B\u3068\u6226\u306B\u624B\u6BB5\u306F\u9078\u3070\u306A\u3044",
    "the best of both worlds": "\u3044\u3044\u3068\u3053\u53D6\u308A",
    "beauty is in the eye of the beholder": "\u7F8E\u3057\u3055\u306F\u898B\u308B\u4EBA\u306E\u76EE\u306B\u5BBF\u308B",
    "if you don't mind my saying...": "\u5DEE\u3057\u652F\u3048\u306A\u3051\u308C\u3070\u7533\u3057\u4E0A\u3052\u307E\u3059\u304C\u2026",
    "i couldn't help but notice...": "\u3064\u3044\u6C17\u3065\u3044\u3066\u3057\u307E\u3063\u305F\u306E\u3067\u3059\u304C\u2026",
    "forgive me for saying so...": "\u3053\u3093\u306A\u3053\u3068\u3092\u8A00\u3063\u3066\u5931\u793C\u3067\u3059\u304C\u2026",
    "without wishing to offend...": "\u5931\u793C\u3092\u627F\u77E5\u3067\u7533\u3057\u4E0A\u3052\u308B\u3068\u2026",
    "i hope you won't take this the wrong way...": "\u60AA\u304F\u53D7\u3051\u53D6\u3089\u306A\u3044\u3067\u3044\u305F\u3060\u304D\u305F\u3044\u306E\u3067\u3059\u304C\u2026",
    "not to put too fine a point on it...": "\u7387\u76F4\u306B\u7533\u3057\u4E0A\u3052\u308B\u3068\u2026",
    "to be perfectly frank...": "\u7387\u76F4\u306B\u8A00\u3048\u3070\u2026",
    "between you and me...": "\u3053\u3053\u3060\u3051\u306E\u8A71\u3067\u3059\u304C\u2026",
    "off the record...": "\u3053\u3053\u3060\u3051\u306E\u8A71\u3067\u3059\u304C\u2026",
    "strictly confidential...": "\u6975\u79D8\u3067\u3059\u304C\u2026",
    "to whom it may concern": "\u95A2\u4FC2\u5404\u4F4D",
    "pursuant to our discussion": "\u5148\u65E5\u306E\u5354\u8B70\u306B\u5F93\u3044",
    "in accordance with": "\u301C\u306B\u5F93\u3063\u3066",
    "notwithstanding the foregoing": "\u524D\u8FF0\u306B\u304B\u304B\u308F\u3089\u305A",
    "herein lies the problem": "\u3053\u3053\u306B\u554F\u984C\u304C\u3042\u308A\u307E\u3059"
  };
  var EXTRA_EXACT_TRANSLATIONS = {
    "a dozen": "1\u30C0\u30FC\u30B9",
    "a key factor is...": "\u91CD\u8981\u306A\u8981\u7D20\u306F\u2026\u3067\u3059",
    "a quarter": "4\u5206\u306E1",
    "a significant aspect is...": "\u5927\u5207\u306A\u5074\u9762\u306F\u2026\u3067\u3059",
    "according to recent research...": "\u6700\u8FD1\u306E\u7814\u7A76\u306B\u3088\u308B\u3068\u2026",
    "according to...": "\u2026\u306B\u3088\u308B\u3068",
    "actions speak louder than words": "\u8A00\u8449\u3088\u308A\u884C\u52D5\u304C\u3082\u306E\u3092\u8A00\u3046",
    "along the same lines...": "\u540C\u3058\u6D41\u308C\u3067\u8A00\u3046\u3068\u2026",
    "any updates?": "\u9032\u6357\u306F\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "are you married?": "\u7D50\u5A5A\u3057\u3066\u3044\u307E\u3059\u304B\uFF1F",
    "are you serious?": "\u672C\u6C17\u3067\u3059\u304B\uFF1F",
    "as a result...": "\u305D\u306E\u7D50\u679C\u2026",
    "as far as x is concerned...": "\u305D\u306E\u70B9\u306B\u95A2\u3057\u3066\u8A00\u3048\u3070\u2026",
    "as it were...": "\u3044\u308F\u3070\u2026",
    "as per our conversation": "\u5148\u307B\u3069\u306E\u4F1A\u8A71\u306E\u3068\u304A\u308A",
    "back to square one": "\u632F\u308A\u51FA\u3057\u306B\u623B\u308B",
    "be that as it may...": "\u305D\u3046\u3060\u3068\u3057\u3066\u3082\u2026",
    "beat around the bush": "\u9060\u56DE\u3057\u306B\u8A00\u3046",
    "better late than never": "\u9045\u308C\u3066\u3082\u3084\u3089\u306A\u3044\u3088\u308A\u306F\u307E\u3057",
    "bite off more than you can chew": "\u624B\u306B\u8CA0\u3048\u306A\u3044\u3053\u3068\u3092\u5F15\u304D\u53D7\u3051\u308B",
    "boarding pass": "\u642D\u4E57\u5238",
    "break a leg": "\u9811\u5F35\u3063\u3066",
    "break the ice": "\u5834\u3092\u548C\u307E\u305B\u308B",
    "building on that idea...": "\u305D\u306E\u8003\u3048\u3092\u5E83\u3052\u308B\u3068\u2026",
    "burn the midnight oil": "\u591C\u9045\u304F\u307E\u3067\u9811\u5F35\u308B",
    "by contrast...": "\u305D\u308C\u306B\u5BFE\u3057\u3066\u2026",
    "by the same token...": "\u540C\u69D8\u306B\u2026",
    "by the way": "\u3068\u3053\u308D\u3067",
    "call it a day": "\u4ECA\u65E5\u306F\u3053\u3053\u307E\u3067\u306B\u3059\u308B",
    "call the police": "\u8B66\u5BDF\u3092\u547C\u3093\u3067\u304F\u3060\u3055\u3044",
    "can i make an appointment?": "\u4E88\u7D04\u3067\u304D\u307E\u3059\u304B\uFF1F",
    "can i see the room?": "\u90E8\u5C4B\u3092\u898B\u305B\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "can i speak to the manager?": "\u8CAC\u4EFB\u8005\u3068\u8A71\u305B\u307E\u3059\u304B\uFF1F",
    "can i switch seats?": "\u5E2D\u3092\u66FF\u3048\u3066\u3082\u3044\u3044\u3067\u3059\u304B\uFF1F",
    "can we have separate checks?": "\u4F1A\u8A08\u3092\u5225\u3005\u306B\u3067\u304D\u307E\u3059\u304B\uFF1F",
    "can we reschedule?": "\u4E88\u5B9A\u3092\u5909\u66F4\u3067\u304D\u307E\u3059\u304B\uFF1F",
    "can we see the menu?": "\u30E1\u30CB\u30E5\u30FC\u3092\u898B\u305B\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "can you fix it?": "\u76F4\u3057\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "can you help me with...?": "\u2026\u3092\u624B\u4F1D\u3063\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "can you make it without...?": "\u2026\u629C\u304D\u3067\u4F5C\u3063\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "can you repeat that?": "\u3082\u3046\u4E00\u5EA6\u8A00\u3063\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "can you replace it?": "\u4EA4\u63DB\u3057\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "can you speak more slowly?": "\u3082\u3046\u5C11\u3057\u3086\u3063\u304F\u308A\u8A71\u3057\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "climate change": "\u6C17\u5019\u5909\u52D5",
    "cost a fortune": "\u3068\u3066\u3082\u9AD8\u304F\u3064\u304F",
    "could you send that in writing?": "\u305D\u308C\u3092\u6587\u9762\u3067\u9001\u3063\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "could you store this for me?": "\u3053\u308C\u3092\u9810\u304B\u3063\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "could you write it down?": "\u66F8\u3044\u3066\u3082\u3089\u3048\u307E\u3059\u304B\uFF1F",
    "cut to the chase": "\u8981\u70B9\u3092\u8A00\u3046",
    "despite that...": "\u305D\u308C\u306B\u3082\u304B\u304B\u308F\u3089\u305A\u2026",
    "do you have a room available?": "\u7A7A\u3044\u3066\u3044\u308B\u90E8\u5C4B\u306F\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "do you have a table available?": "\u7A7A\u3044\u3066\u3044\u308B\u5E2D\u306F\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "do you have siblings?": "\u5144\u5F1F\u59C9\u59B9\u306F\u3044\u307E\u3059\u304B\uFF1F",
    "do i need a prescription?": "\u51E6\u65B9\u7B8B\u306F\u5FC5\u8981\u3067\u3059\u304B\uFF1F",
    "do you understand me?": "\u79C1\u306E\u8A00\u3063\u3066\u3044\u308B\u3053\u3068\u304C\u308F\u304B\u308A\u307E\u3059\u304B\uFF1F",
    "do you want to go to...?": "\u2026\u306B\u884C\u304D\u305F\u3044\u3067\u3059\u304B\uFF1F",
    "don't count your chickens before they hatch": "\u6355\u3089\u306C\u72F8\u306E\u76AE\u7B97\u7528",
    "don't worry": "\u5FC3\u914D\u3057\u306A\u3044\u3067",
    "even so...": "\u305D\u308C\u3067\u3082\u2026",
    "every cloud has a silver lining": "\u60AA\u3044\u3053\u3068\u306E\u4E2D\u306B\u3082\u826F\u3044\u9762\u304C\u3042\u308B",
    "evidence suggests...": "\u8A3C\u62E0\u304C\u793A\u3057\u3066\u3044\u308B\u306E\u306F\u2026",
    "for how many nights?": "\u4F55\u6CCA\u3067\u3059\u304B\uFF1F",
    "for lack of a better word...": "\u307B\u304B\u306B\u3044\u3044\u8A00\u8449\u304C\u306A\u3044\u306E\u3067\u8A00\u3046\u3068\u2026",
    "forget it": "\u6C17\u306B\u3057\u306A\u3044\u3067",
    "free time": "\u81EA\u7531\u6642\u9593",
    "from a practical standpoint...": "\u5B9F\u969B\u7684\u306A\u89B3\u70B9\u304B\u3089\u8A00\u3046\u3068\u2026",
    "from a theoretical perspective...": "\u7406\u8AD6\u7684\u306A\u89B3\u70B9\u304B\u3089\u8A00\u3046\u3068\u2026",
    "get cold feet": "\u6016\u3058\u6C17\u3065\u304F",
    "get the ball rolling": "\u8A71\u3092\u52D5\u304B\u3057\u59CB\u3081\u308B",
    "good luck!": "\u9811\u5F35\u3063\u3066\uFF01",
    "have you read...?": "\u2026\u3092\u8AAD\u307F\u307E\u3057\u305F\u304B\uFF1F",
    "have you seen...?": "\u2026\u3092\u898B\u307E\u3057\u305F\u304B\uFF1F",
    "help me please": "\u52A9\u3051\u3066\u304F\u3060\u3055\u3044",
    "hit the nail on the head": "\u7684\u3092\u5C04\u308B",
    "how do i get to the city center?": "\u5E02\u5185\u4E2D\u5FC3\u90E8\u3078\u306F\u3069\u3046\u884C\u3051\u3070\u3044\u3044\u3067\u3059\u304B\uFF1F",
    "how do you say...?": "\u2026\u306F\u3069\u3046\u8A00\u3044\u307E\u3059\u304B\uFF1F",
    "how long are you staying?": "\u3069\u306E\u304F\u3089\u3044\u6EDE\u5728\u3057\u307E\u3059\u304B\uFF1F",
    "how long is the wait?": "\u5F85\u3061\u6642\u9593\u306F\u3069\u306E\u304F\u3089\u3044\u3067\u3059\u304B\uFF1F",
    "how long will it take?": "\u3069\u306E\u304F\u3089\u3044\u304B\u304B\u308A\u307E\u3059\u304B\uFF1F",
    "how many rooms?": "\u90E8\u5C4B\u306F\u3044\u304F\u3064\u3067\u3059\u304B\uFF1F",
    "i agree": "\u8CDB\u6210\u3067\u3059",
    "i am from...": "\u79C1\u306F\u2026\u51FA\u8EAB\u3067\u3059",
    "i am...": "\u79C1\u306F\u2026\u3067\u3059",
    "i beg to differ": "\u5931\u793C\u3067\u3059\u304C\u7570\u306A\u308B\u610F\u898B\u3067\u3059",
    "i can't eat...": "\u2026\u306F\u98DF\u3079\u3089\u308C\u307E\u305B\u3093",
    "i completely disagree": "\u307E\u3063\u305F\u304F\u540C\u610F\u3067\u304D\u307E\u305B\u3093",
    "i could be wrong, but...": "\u9593\u9055\u3063\u3066\u3044\u308B\u304B\u3082\u3057\u308C\u307E\u305B\u3093\u304C\u2026",
    "i disagree": "\u53CD\u5BFE\u3067\u3059",
    "i don't feel well": "\u5177\u5408\u304C\u3088\u304F\u3042\u308A\u307E\u305B\u3093",
    "i don't think so": "\u305D\u3046\u306F\u601D\u3044\u307E\u305B\u3093",
    "i enjoy...": "\u2026\u3092\u697D\u3057\u3093\u3067\u3044\u307E\u3059",
    "i feel airsick": "\u98DB\u884C\u6A5F\u9154\u3044\u3057\u3066\u3044\u307E\u3059",
    "i hate...": "\u2026\u304C\u5ACC\u3044\u3067\u3059",
    "i have a fever": "\u71B1\u304C\u3042\u308A\u307E\u3059",
    "i have a meeting": "\u4F1A\u8B70\u304C\u3042\u308A\u307E\u3059",
    "i have a problem": "\u554F\u984C\u304C\u3042\u308A\u307E\u3059",
    "i have a reservation": "\u4E88\u7D04\u3057\u3066\u3044\u307E\u3059",
    "i have a reservation under...": "\u2026\u306E\u540D\u524D\u3067\u4E88\u7D04\u3057\u3066\u3044\u307E\u3059",
    "i have nothing to declare": "\u7533\u544A\u3059\u308B\u3082\u306E\u306F\u3042\u308A\u307E\u305B\u3093",
    "i have two children": "\u5B50\u3069\u3082\u304C\u4E8C\u4EBA\u3044\u307E\u3059",
    "i highly recommend...": "\u2026\u3092\u5F37\u304F\u304A\u3059\u3059\u3081\u3057\u307E\u3059",
    "i hope so": "\u305D\u3046\u3060\u3068\u3044\u3044\u3067\u3059\u306D",
    "i hurt my...": "\u2026\u3092\u3051\u304C\u3057\u307E\u3057\u305F",
    "i like to...": "\u2026\u3059\u308B\u306E\u304C\u597D\u304D\u3067\u3059",
    "i live alone": "\u4E00\u4EBA\u66AE\u3089\u3057\u3067\u3059",
    "i live in an apartment": "\u30A2\u30D1\u30FC\u30C8\u306B\u4F4F\u3093\u3067\u3044\u307E\u3059",
    "i live with...": "\u2026\u3068\u4E00\u7DD2\u306B\u4F4F\u3093\u3067\u3044\u307E\u3059",
    "i love...": "\u2026\u304C\u5927\u597D\u304D\u3067\u3059",
    "i miss my family": "\u5BB6\u65CF\u304C\u604B\u3057\u3044\u3067\u3059",
    "i need a doctor": "\u533B\u8005\u304C\u5FC5\u8981\u3067\u3059",
    "i need medicine for...": "\u2026\u306E\u85AC\u304C\u5FC5\u8981\u3067\u3059",
    "i need more towels": "\u30BF\u30AA\u30EB\u3092\u3082\u3063\u3068\u304A\u9858\u3044\u3057\u307E\u3059",
    "i need this urgently": "\u3053\u308C\u304C\u81F3\u6025\u5FC5\u8981\u3067\u3059",
    "i need to see a doctor": "\u533B\u8005\u306B\u8A3A\u3066\u3082\u3089\u3046\u5FC5\u8981\u304C\u3042\u308A\u307E\u3059",
    "i regret...": "\u2026\u3092\u6B8B\u5FF5\u306B\u601D\u3044\u307E\u3059",
    "i see your point, but...": "\u8A00\u3044\u305F\u3044\u3053\u3068\u306F\u308F\u304B\u308A\u307E\u3059\u304C\u2026",
    "i speak a little": "\u5C11\u3057\u8A71\u305B\u307E\u3059",
    "i strongly believe that...": "\u79C1\u306F\u2026\u3068\u5F37\u304F\u601D\u3044\u307E\u3059",
    "i think so": "\u305D\u3046\u601D\u3044\u307E\u3059",
    "i understand what you mean, but...": "\u8A00\u3044\u305F\u3044\u3053\u3068\u306F\u308F\u304B\u308A\u307E\u3059\u304C\u2026",
    "i want to file a complaint": "\u82E6\u60C5\u3092\u7533\u3057\u7ACB\u3066\u305F\u3044\u3067\u3059",
    "i was blown away": "\u3068\u3066\u3082\u611F\u52D5\u3057\u307E\u3057\u305F",
    "i work as a...": "\u79C1\u306F\u2026\u3068\u3057\u3066\u50CD\u3044\u3066\u3044\u307E\u3059",
    "i work from home": "\u5728\u5B85\u3067\u50CD\u3044\u3066\u3044\u307E\u3059",
    "i'd like a refund": "\u8FD4\u91D1\u3057\u3066\u307B\u3057\u3044\u3067\u3059",
    "i'd like to exchange this": "\u3053\u308C\u3092\u4EA4\u63DB\u3057\u305F\u3044\u3067\u3059",
    "i'll be there at...": "\u2026\u306B\u7740\u304D\u307E\u3059",
    "i'll follow up with you": "\u3042\u3068\u3067\u6539\u3081\u3066\u9023\u7D61\u3057\u307E\u3059",
    "i'll keep you posted": "\u9032\u6357\u3092\u304A\u77E5\u3089\u305B\u3057\u307E\u3059",
    "i'll loop you in": "\u3042\u306A\u305F\u3082\u5171\u6709\u306B\u5165\u308C\u307E\u3059",
    "i'll never forget...": "\u2026\u306F\u6C7A\u3057\u3066\u5FD8\u308C\u307E\u305B\u3093",
    "i'll pick you up": "\u8FCE\u3048\u306B\u884C\u304D\u307E\u3059",
    "i'll send you the agenda": "\u8B70\u984C\u3092\u9001\u308A\u307E\u3059",
    "i'm a student": "\u5B66\u751F\u3067\u3059",
    "i'm allergic to...": "\u2026\u306B\u30A2\u30EC\u30EB\u30AE\u30FC\u304C\u3042\u308A\u307E\u3059",
    "i'm busy": "\u5FD9\u3057\u3044\u3067\u3059",
    "i'm busy that day": "\u305D\u306E\u65E5\u306F\u5FD9\u3057\u3044\u3067\u3059",
    "i'm dizzy": "\u3081\u307E\u3044\u304C\u3057\u307E\u3059",
    "i'm feeling...": "\u2026\u306A\u6C17\u5206\u3067\u3059",
    "i'm fine": "\u5143\u6C17\u3067\u3059",
    "i'm grateful for...": "\u2026\u306B\u611F\u8B1D\u3057\u3066\u3044\u307E\u3059",
    "i'm here for business": "\u4ED5\u4E8B\u3067\u6765\u3066\u3044\u307E\u3059",
    "i'm here on vacation": "\u4F11\u6687\u3067\u6765\u3066\u3044\u307E\u3059",
    "i'm just passing through": "\u901A\u308A\u304C\u304B\u3063\u305F\u3060\u3051\u3067\u3059",
    "i'm learning": "\u52C9\u5F37\u4E2D\u3067\u3059",
    "i'm looking forward to it": "\u697D\u3057\u307F\u306B\u3057\u3066\u3044\u307E\u3059",
    "i'm lost": "\u9053\u306B\u8FF7\u3044\u307E\u3057\u305F",
    "i'm nauseous": "\u5410\u304D\u6C17\u304C\u3057\u307E\u3059",
    "i'm not entirely sure": "\u5B8C\u5168\u306B\u306F\u81EA\u4FE1\u304C\u3042\u308A\u307E\u305B\u3093",
    "i'm not sure": "\u3088\u304F\u308F\u304B\u308A\u307E\u305B\u3093",
    "i'm on my way": "\u5411\u304B\u3063\u3066\u3044\u307E\u3059",
    "i'm on vacation": "\u4F11\u6687\u4E2D\u3067\u3059",
    "i'm retired": "\u9000\u8077\u3057\u3066\u3044\u307E\u3059",
    "i'm running late": "\u5C11\u3057\u9045\u308C\u3066\u3044\u307E\u3059",
    "i'm sick": "\u5177\u5408\u304C\u60AA\u3044\u3067\u3059",
    "i'm single": "\u72EC\u8EAB\u3067\u3059",
    "i'm staying for... days": "\u2026\u65E5\u9593\u6EDE\u5728\u3057\u307E\u3059",
    "i'm unemployed": "\u7121\u8077\u3067\u3059",
    "maybe later": "\u307E\u305F\u3042\u3068\u3067",
    "i've been to...": "\u2026\u306B\u884C\u3063\u305F\u3053\u3068\u304C\u3042\u308A\u307E\u3059",
    "i've lost my passport": "\u30D1\u30B9\u30DD\u30FC\u30C8\u3092\u306A\u304F\u3057\u307E\u3057\u305F",
    "i've missed my flight": "\u98DB\u884C\u6A5F\u306B\u4E57\u308A\u9045\u308C\u307E\u3057\u305F",
    "i've never been to...": "\u2026\u306B\u884C\u3063\u305F\u3053\u3068\u304C\u3042\u308A\u307E\u305B\u3093",
    "i've never tried...": "\u2026\u3092\u8A66\u3057\u305F\u3053\u3068\u304C\u3042\u308A\u307E\u305B\u3093",
    "i've tried...": "\u2026\u3092\u8A66\u3057\u305F\u3053\u3068\u304C\u3042\u308A\u307E\u3059",
    "if i had to guess...": "\u63A8\u6E2C\u3059\u308B\u306A\u3089\u2026",
    "if i may say so...": "\u5DEE\u3057\u652F\u3048\u306A\u3051\u308C\u3070\u2026",
    "if you will...": "\u3042\u3048\u3066\u8A00\u3046\u306A\u3089\u2026",
    "in a manner of speaking...": "\u3044\u308F\u3070\u2026",
    "in a nutshell": "\u8981\u3059\u308B\u306B",
    "in addition to...": "\u2026\u306B\u52A0\u3048\u3066",
    "in contrast to...": "\u2026\u3068\u306F\u5BFE\u7167\u7684\u306B",
    "in fact...": "\u5B9F\u306F\u2026",
    "in lieu of...": "\u2026\u306E\u4EE3\u308F\u308A\u306B",
    "in light of...": "\u2026\u3092\u8E0F\u307E\u3048\u308B\u3068",
    "in my free time...": "\u81EA\u7531\u6642\u9593\u306B\u306F\u2026",
    "in other words...": "\u8A00\u3044\u63DB\u3048\u308B\u3068\u2026",
    "in practical terms...": "\u5B9F\u969B\u306B\u8A00\u3046\u3068\u2026",
    "in practice...": "\u5B9F\u969B\u306B\u306F\u2026",
    "in the same vein...": "\u540C\u3058\u3088\u3046\u306B\u8A00\u3048\u3070\u2026",
    "in the wake of...": "\u2026\u3092\u53D7\u3051\u3066",
    "in theory...": "\u7406\u8AD6\u4E0A\u306F\u2026",
    "in this context...": "\u3053\u306E\u6587\u8108\u3067\u306F\u2026",
    "is breakfast included?": "\u671D\u98DF\u306F\u542B\u307E\u308C\u3066\u3044\u307E\u3059\u304B\uFF1F",
    "is there a layover?": "\u4E57\u308A\u7D99\u304E\u306F\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "is this dish spicy?": "\u3053\u306E\u6599\u7406\u306F\u8F9B\u3044\u3067\u3059\u304B\uFF1F",
    "is this seat taken?": "\u3053\u306E\u5E2D\u306F\u7A7A\u3044\u3066\u3044\u307E\u3059\u304B\uFF1F",
    "it costs an arm and a leg": "\u3068\u3066\u3082\u9AD8\u3044\u3067\u3059",
    "it depends": "\u5834\u5408\u306B\u3088\u308A\u307E\u3059",
    "it depends on...": "\u2026\u306B\u3088\u308A\u307E\u3059",
    "it doesn't matter": "\u554F\u984C\u3042\u308A\u307E\u305B\u3093",
    "it doesn't work": "\u52D5\u304D\u307E\u305B\u3093",
    "it goes without saying that...": "\u8A00\u3046\u307E\u3067\u3082\u306A\u304F\u2026",
    "it has been demonstrated that...": "\u2026\u3067\u3042\u308B\u3053\u3068\u304C\u793A\u3055\u308C\u3066\u3044\u307E\u3059",
    "it hurts here": "\u3053\u3053\u304C\u75DB\u3044\u3067\u3059",
    "it is widely acknowledged that...": "\u2026\u306F\u5E83\u304F\u8A8D\u3081\u3089\u308C\u3066\u3044\u307E\u3059",
    "it is worth noting that...": "\u6CE8\u76EE\u3059\u3079\u304D\u3053\u3068\u306B\u2026",
    "it really makes you think": "\u3068\u3066\u3082\u8003\u3048\u3055\u305B\u3089\u308C\u307E\u3059",
    "it reminded me of...": "\u2026\u3092\u601D\u3044\u51FA\u3057\u307E\u3057\u305F",
    "it should be emphasized that...": "\u5F37\u8ABF\u3059\u3079\u304D\u306F\u2026",
    "it stands to reason that...": "\u5F53\u7136\u2026\u3068\u8A00\u3048\u307E\u3059",
    "it was amazing": "\u7D20\u6674\u3089\u3057\u304B\u3063\u305F\u3067\u3059",
    "it was different from...": "\u2026\u3068\u306F\u9055\u3063\u3066\u3044\u307E\u3057\u305F",
    "it was similar to...": "\u2026\u306B\u4F3C\u3066\u3044\u307E\u3057\u305F",
    "it was terrible": "\u3072\u3069\u304B\u3063\u305F\u3067\u3059",
    "it was thought-provoking": "\u8003\u3048\u3055\u305B\u3089\u308C\u307E\u3057\u305F",
    "it was worth it": "\u3084\u308B\u4FA1\u5024\u304C\u3042\u308A\u307E\u3057\u305F",
    "it's a must-see": "\u305C\u3072\u898B\u308B\u3079\u304D\u3067\u3059",
    "it's boring": "\u9000\u5C48\u3067\u3059",
    "it's broken": "\u58CA\u308C\u3066\u3044\u307E\u3059",
    "it's difficult to tell": "\u5224\u65AD\u304C\u96E3\u3057\u3044\u3067\u3059",
    "it's fun": "\u697D\u3057\u3044\u3067\u3059",
    "it's hard to say": "\u4F55\u3068\u3082\u8A00\u3048\u307E\u305B\u3093",
    "it's interesting": "\u9762\u767D\u3044\u3067\u3059",
    "it's nothing": "\u4F55\u3067\u3082\u3042\u308A\u307E\u305B\u3093",
    "it's obvious that...": "\u2026\u306F\u660E\u3089\u304B\u3067\u3059",
    "it's overrated": "\u8A55\u4FA1\u3055\u308C\u3059\u304E\u3067\u3059",
    "it's raining cats and dogs": "\u571F\u7802\u964D\u308A\u3067\u3059",
    "it's underrated": "\u904E\u5C0F\u8A55\u4FA1\u3055\u308C\u3066\u3044\u307E\u3059",
    "it's unlikely that...": "\u2026\u306F\u8D77\u3053\u308A\u305D\u3046\u306B\u3042\u308A\u307E\u305B\u3093",
    "keep in touch": "\u9023\u7D61\u3092\u53D6\u308A\u5408\u3044\u307E\u3057\u3087\u3046",
    "keep me in the loop": "\u79C1\u306B\u3082\u5171\u6709\u3057\u3066\u304F\u3060\u3055\u3044",
    "keep the change": "\u304A\u3064\u308A\u306F\u53D6\u3063\u3066\u304A\u3044\u3066\u304F\u3060\u3055\u3044",
    "kill two birds with one stone": "\u4E00\u77F3\u4E8C\u9CE5",
    "let me explain": "\u8AAC\u660E\u3055\u305B\u3066\u304F\u3060\u3055\u3044",
    "let me get back to you on that": "\u305D\u308C\u306B\u3064\u3044\u3066\u306F\u6539\u3081\u3066\u9023\u7D61\u3057\u307E\u3059",
    "let the cat out of the bag": "\u79D8\u5BC6\u3092\u6F0F\u3089\u3059",
    "let's circle back to this": "\u3053\u306E\u8A71\u306B\u307E\u305F\u623B\u308A\u307E\u3057\u3087\u3046",
    "let's do this again": "\u307E\u305F\u3084\u308A\u307E\u3057\u3087\u3046",
    "let's get down to business": "\u672C\u984C\u306B\u5165\u308A\u307E\u3057\u3087\u3046",
    "let's go to...": "\u2026\u306B\u884C\u304D\u307E\u3057\u3087\u3046",
    "let's meet at...": "\u2026\u3067\u4F1A\u3044\u307E\u3057\u3087\u3046",
    "let's schedule a meeting": "\u4F1A\u8B70\u3092\u4E88\u5B9A\u3057\u307E\u3057\u3087\u3046",
    "let's split it": "\u5272\u308A\u52D8\u306B\u3057\u307E\u3057\u3087\u3046",
    "let's touch base": "\u3044\u3063\u305F\u3093\u9023\u7D61\u3092\u53D6\u308A\u307E\u3057\u3087\u3046",
    "living room": "\u5C45\u9593",
    "logic dictates that...": "\u8AD6\u7406\u7684\u306B\u8A00\u3048\u3070\u2026",
    "looking back...": "\u632F\u308A\u8FD4\u308B\u3068\u2026",
    "loosely speaking...": "\u5927\u307E\u304B\u306B\u8A00\u3046\u3068\u2026",
    "main course": "\u30E1\u30A4\u30F3\u6599\u7406",
    "more or less": "\u3060\u3044\u305F\u3044",
    "moving forward...": "\u4ECA\u5F8C\u306F\u2026",
    "my head hurts": "\u982D\u304C\u75DB\u3044\u3067\u3059",
    "my luggage is missing": "\u8377\u7269\u304C\u898B\u5F53\u305F\u308A\u307E\u305B\u3093",
    "my parents live in...": "\u4E21\u89AA\u306F\u2026\u306B\u4F4F\u3093\u3067\u3044\u307E\u3059",
    "never mind": "\u6C17\u306B\u3057\u306A\u3044\u3067\u304F\u3060\u3055\u3044",
    "next time i'll...": "\u6B21\u306F\u2026\u3057\u307E\u3059",
    "no problem": "\u554F\u984C\u3042\u308A\u307E\u305B\u3093",
    "not now": "\u4ECA\u306F\u3060\u3081\u3067\u3059",
    "not only... but also...": "\u2026\u3060\u3051\u3067\u306A\u304F\u2026\u3082",
    "of course": "\u3082\u3061\u308D\u3093",
    "on the other hand...": "\u4E00\u65B9\u3067\u2026",
    "on the same page": "\u8A8D\u8B58\u304C\u4E00\u81F4\u3057\u3066\u3044\u308B",
    "once in a blue moon": "\u3081\u3063\u305F\u306B\u306A\u3044",
    "one cannot help but notice...": "\u2026\u306B\u6C17\u3065\u304B\u305A\u306B\u306F\u3044\u3089\u308C\u306A\u3044",
    "one hundred": "\u767E",
    "only time will tell": "\u6642\u9593\u304C\u305F\u3066\u3070\u308F\u304B\u308B",
    "piece of cake": "\u671D\u98EF\u524D",
    "pleased to meet you": "\u304A\u4F1A\u3044\u3067\u304D\u3066\u3046\u308C\u3057\u3044\u3067\u3059",
    "receipt, please": "\u30EC\u30B7\u30FC\u30C8\u3092\u304A\u9858\u3044\u3057\u307E\u3059",
    "really?": "\u672C\u5F53\u3067\u3059\u304B\uFF1F",
    "scholars argue that...": "\u7814\u7A76\u8005\u305F\u3061\u306F\u2026\u3068\u8AD6\u3058\u3066\u3044\u307E\u3059",
    "shall we...?": "\u2026\u3057\u307E\u3057\u3087\u3046\u304B\uFF1F",
    "so to speak...": "\u3044\u308F\u3070\u2026",
    "something's wrong with...": "\u2026\u306E\u8ABF\u5B50\u304C\u304A\u304B\u3057\u3044\u3067\u3059",
    "sorry, i can't make it": "\u3059\u307F\u307E\u305B\u3093\u3001\u884C\u3051\u307E\u305B\u3093",
    "spill the beans": "\u79D8\u5BC6\u3092\u3070\u3089\u3059",
    "strictly speaking...": "\u53B3\u5BC6\u306B\u8A00\u3048\u3070\u2026",
    "studies have shown that...": "\u7814\u7A76\u3067\u2026\u3068\u793A\u3055\u308C\u3066\u3044\u307E\u3059",
    "studies show that...": "\u7814\u7A76\u3067\u2026\u3068\u793A\u3055\u308C\u3066\u3044\u307E\u3059",
    "surely you can see that...": "\u2026\u304C\u308F\u304B\u308B\u306F\u305A\u3067\u3059",
    "take care": "\u304A\u5927\u4E8B\u306B",
    "taking that further...": "\u3055\u3089\u306B\u8A00\u3048\u3070\u2026",
    "technically speaking...": "\u6280\u8853\u7684\u306B\u8A00\u3048\u3070\u2026",
    "thanks a lot": "\u3069\u3046\u3082\u3042\u308A\u304C\u3068\u3046",
    "thanks for inviting me": "\u8A98\u3063\u3066\u304F\u308C\u3066\u3042\u308A\u304C\u3068\u3046",
    "that being said...": "\u3068\u306F\u3044\u3048\u2026",
    "that makes me angry": "\u305D\u308C\u306F\u8179\u304C\u7ACB\u3061\u307E\u3059",
    "that may be true, but...": "\u305D\u308C\u306F\u305D\u3046\u304B\u3082\u3057\u308C\u307E\u305B\u3093\u304C\u2026",
    "that raises an interesting question...": "\u305D\u308C\u306F\u8208\u5473\u6DF1\u3044\u7591\u554F\u3092\u751F\u307F\u307E\u3059\u2026",
    "that remains to be seen": "\u305D\u308C\u306F\u307E\u3060\u308F\u304B\u308A\u307E\u305B\u3093",
    "that's not necessarily true": "\u5FC5\u305A\u3057\u3082\u305D\u3046\u3068\u306F\u9650\u308A\u307E\u305B\u3093",
    "that's true": "\u305D\u306E\u3068\u304A\u308A\u3067\u3059",
    "the (feminine)": "\u5B9A\u51A0\u8A5E\uFF08\u5973\u6027\u5F62\uFF09",
    "the (masculine)": "\u5B9A\u51A0\u8A5E\uFF08\u7537\u6027\u5F62\uFF09",
    "the ball is in your court": "\u6B21\u306F\u3042\u306A\u305F\u306E\u756A\u3067\u3059",
    "the best part was...": "\u3044\u3061\u3070\u3093\u826F\u304B\u3063\u305F\u306E\u306F\u2026",
    "the consensus is that...": "\u4E00\u822C\u7684\u306A\u898B\u89E3\u306F\u2026\u3067\u3059",
    "the early bird catches the worm": "\u65E9\u8D77\u304D\u306F\u4E09\u6587\u306E\u5FB3",
    "the point i'm making is...": "\u79C1\u304C\u8A00\u3044\u305F\u3044\u306E\u306F\u2026\u3067\u3059",
    "the project is behind schedule": "\u30D7\u30ED\u30B8\u30A7\u30AF\u30C8\u306F\u4E88\u5B9A\u3088\u308A\u9045\u308C\u3066\u3044\u307E\u3059",
    "the worst part was...": "\u3044\u3061\u3070\u3093\u5927\u5909\u3060\u3063\u305F\u306E\u306F\u2026",
    "there is considerable debate about...": "\u2026\u306B\u3064\u3044\u3066\u306F\u5927\u304D\u306A\u8B70\u8AD6\u304C\u3042\u308A\u307E\u3059",
    "there's a good chance that...": "\u2026\u306E\u53EF\u80FD\u6027\u304C\u9AD8\u3044\u3067\u3059",
    "there's a problem with...": "\u2026\u306B\u554F\u984C\u304C\u3042\u308A\u307E\u3059",
    "there's no denying that...": "\u2026\u306F\u5426\u5B9A\u3067\u304D\u307E\u305B\u3093",
    "there's no doubt that...": "\u2026\u306F\u9593\u9055\u3044\u3042\u308A\u307E\u305B\u3093",
    "this is cold": "\u3053\u308C\u306F\u51B7\u305F\u3044\u3067\u3059",
    "this is defective": "\u3053\u308C\u306F\u4E0D\u826F\u54C1\u3067\u3059",
    "this is for personal use": "\u3053\u308C\u306F\u500B\u4EBA\u4F7F\u7528\u306E\u305F\u3081\u3067\u3059",
    "this is my family": "\u3053\u3061\u3089\u304C\u79C1\u306E\u5BB6\u65CF\u3067\u3059",
    "this is unacceptable": "\u3053\u308C\u306F\u53D7\u3051\u5165\u308C\u3089\u308C\u307E\u305B\u3093",
    "this is...": "\u3053\u308C\u306F\u2026\u3067\u3059",
    "this isn't what i ordered": "\u3053\u308C\u306F\u79C1\u304C\u6CE8\u6587\u3057\u305F\u3082\u306E\u3067\u306F\u3042\u308A\u307E\u305B\u3093",
    "this raises the question of...": "\u3053\u308C\u306B\u3088\u3063\u3066\u2026\u3068\u3044\u3046\u7591\u554F\u304C\u751F\u307E\u308C\u307E\u3059",
    "to a large extent...": "\u5927\u90E8\u5206\u306F\u2026",
    "to be honest...": "\u6B63\u76F4\u306B\u8A00\u3046\u3068\u2026",
    "to clarify...": "\u306F\u3063\u304D\u308A\u3055\u305B\u308B\u3068\u2026",
    "to coin a phrase...": "\u3042\u3048\u3066\u8A00\u8449\u306B\u3059\u308B\u306A\u3089\u2026",
    "to elaborate...": "\u8A73\u3057\u304F\u8A00\u3046\u3068\u2026",
    "to expand on that...": "\u305D\u308C\u3092\u3055\u3089\u306B\u8A00\u3046\u3068\u2026",
    "to put it another way...": "\u5225\u306E\u8A00\u3044\u65B9\u3092\u3059\u308B\u3068\u2026",
    "to some degree...": "\u3042\u308B\u7A0B\u5EA6\u306F\u2026",
    "under the weather": "\u5C11\u3057\u4F53\u8ABF\u304C\u60AA\u3044",
    "vis-\xE0-vis...": "\u2026\u306B\u95A2\u3057\u3066",
    "want to come along?": "\u4E00\u7DD2\u306B\u6765\u307E\u3059\u304B\uFF1F",
    "we need to meet the deadline": "\u7DE0\u3081\u5207\u308A\u306B\u9593\u306B\u5408\u308F\u305B\u308B\u5FC5\u8981\u304C\u3042\u308A\u307E\u3059",
    "we'd like to sit outside": "\u5916\u306E\u5E2D\u306B\u5EA7\u308A\u305F\u3044\u3067\u3059",
    "we're going to...": "\u2026\u306B\u884C\u304F\u4E88\u5B9A\u3067\u3059",
    "we're on track": "\u9806\u8ABF\u3067\u3059",
    "what do you do?": "\u3069\u3093\u306A\u4ED5\u4E8B\u3092\u3057\u3066\u3044\u307E\u3059\u304B\uFF1F",
    "what do you like to do?": "\u4F55\u3092\u3059\u308B\u306E\u304C\u597D\u304D\u3067\u3059\u304B\uFF1F",
    "what are my options?": "\u3069\u3093\u306A\u9078\u629E\u80A2\u304C\u3042\u308A\u307E\u3059\u304B\uFF1F",
    "what are you doing tonight?": "\u4ECA\u591C\u306F\u4F55\u3092\u3057\u307E\u3059\u304B\uFF1F",
    "what did you think of...?": "\u2026\u3092\u3069\u3046\u601D\u3044\u307E\u3057\u305F\u304B\uFF1F",
    "what do you recommend?": "\u304A\u3059\u3059\u3081\u306F\u4F55\u3067\u3059\u304B\uFF1F",
    "what does that mean?": "\u305D\u308C\u306F\u3069\u3046\u3044\u3046\u610F\u5473\u3067\u3059\u304B\uFF1F",
    "what gate?": "\u4F55\u756A\u30B2\u30FC\u30C8\u3067\u3059\u304B\uFF1F",
    "what i'm trying to say is...": "\u79C1\u304C\u8A00\u3044\u305F\u3044\u306E\u306F\u2026\u3067\u3059",
    "what time do you finish work?": "\u4ED5\u4E8B\u306F\u4F55\u6642\u306B\u7D42\u308F\u308A\u307E\u3059\u304B\uFF1F",
    "what time is checkout?": "\u30C1\u30A7\u30C3\u30AF\u30A2\u30A6\u30C8\u306F\u4F55\u6642\u3067\u3059\u304B\uFF1F",
    "what time works for you?": "\u4F55\u6642\u304C\u90FD\u5408\u3044\u3044\u3067\u3059\u304B\uFF1F",
    "what's the specialty?": "\u540D\u7269\u306F\u4F55\u3067\u3059\u304B\uFF1F",
    "what's the status?": "\u72B6\u6CC1\u306F\u3069\u3046\u3067\u3059\u304B\uFF1F",
    "what's the wi-fi password?": "\u30EF\u30A4\u30D5\u30A1\u30A4\u306E\u30D1\u30B9\u30EF\u30FC\u30C9\u306F\u4F55\u3067\u3059\u304B\uFF1F",
    "whatever you prefer": "\u304A\u597D\u304D\u306A\u307B\u3046\u3067\u3069\u3046\u305E",
    "when does boarding start?": "\u642D\u4E57\u306F\u3044\u3064\u59CB\u307E\u308A\u307E\u3059\u304B\uFF1F",
    "when pigs fly": "\u305D\u3093\u306A\u3053\u3068\u306F\u3042\u308A\u3048\u306A\u3044",
    "where are you staying?": "\u3069\u3053\u306B\u6CCA\u307E\u3063\u3066\u3044\u307E\u3059\u304B\uFF1F",
    "where do i pick up my luggage?": "\u8377\u7269\u306F\u3069\u3053\u3067\u53D7\u3051\u53D6\u308A\u307E\u3059\u304B\uFF1F",
    "where should we meet?": "\u3069\u3053\u3067\u4F1A\u3044\u307E\u3057\u3087\u3046\u304B\uFF1F",
    "where's the hospital?": "\u75C5\u9662\u306F\u3069\u3053\u3067\u3059\u304B\uFF1F",
    "while it's true that...": "\u305F\u3057\u304B\u306B\u2026\u3067\u3059\u304C",
    "wi-fi": "\u30EF\u30A4\u30D5\u30A1\u30A4",
    "with all due respect...": "\u5931\u793C\u3092\u627F\u77E5\u3067\u7533\u3057\u4E0A\u3052\u307E\u3059\u304C\u2026",
    "with pleasure": "\u559C\u3093\u3067",
    "with regard to...": "\u2026\u306B\u95A2\u3057\u3066",
    "without a doubt...": "\u9593\u9055\u3044\u306A\u304F\u2026",
    "would you like to join us?": "\u3054\u4E00\u7DD2\u3057\u307E\u305B\u3093\u304B\uFF1F",
    "would you like to...?": "\u2026\u3057\u307E\u305B\u3093\u304B\uFF1F",
    "wouldn't you agree that...?": "\u2026\u3060\u3068\u601D\u3044\u307E\u305B\u3093\u304B\uFF1F",
    "you can't have your cake and eat it too": "\u3044\u3044\u3068\u3053\u53D6\u308A\u306F\u3067\u304D\u306A\u3044",
    "you made a mistake": "\u9593\u9055\u3048\u307E\u3057\u305F",
    "and you?": "\u3042\u306A\u305F\u306F\uFF1F",
    "a table for four, please": "4\u4EBA\u7528\u306E\u5E2D\u3092\u304A\u9858\u3044\u3057\u307E\u3059",
    "on weekends...": "\u9031\u672B\u306B\u306F\u2026",
    "you're right": "\u3042\u306A\u305F\u306E\u8A00\u3046\u3068\u304A\u308A\u3067\u3059"
  };
  Object.assign(EXACT_TRANSLATIONS, EXTRA_EXACT_TRANSLATIONS);
  var WORD_TRANSLATIONS = {
    name: "\u540D\u524D",
    age: "\u5E74\u9F62",
    from: "\u51FA\u8EAB",
    where: "\u3069\u3053",
    who: "\u8AB0",
    what: "\u4F55",
    when: "\u3044\u3064",
    why: "\u306A\u305C",
    how: "\u3069\u3046",
    which: "\u3069\u308C",
    i: "\u79C1",
    you: "\u3042\u306A\u305F",
    he: "\u5F7C",
    she: "\u5F7C\u5973",
    we: "\u79C1\u305F\u3061",
    they: "\u5F7C\u3089",
    country: "\u56FD",
    city: "\u90FD\u5E02",
    language: "\u8A00\u8A9E",
    nationality: "\u56FD\u7C4D",
    zero: "\u30BC\u30ED",
    one: "\u4E00",
    two: "\u4E8C",
    three: "\u4E09",
    four: "\u56DB",
    five: "\u4E94",
    six: "\u516D",
    seven: "\u4E03",
    eight: "\u516B",
    nine: "\u4E5D",
    ten: "\u5341",
    eleven: "\u5341\u4E00",
    twelve: "\u5341\u4E8C",
    thirteen: "\u5341\u4E09",
    fourteen: "\u5341\u56DB",
    fifteen: "\u5341\u4E94",
    sixteen: "\u5341\u516D",
    seventeen: "\u5341\u4E03",
    eighteen: "\u5341\u516B",
    nineteen: "\u5341\u4E5D",
    twenty: "\u4E8C\u5341",
    thirty: "\u4E09\u5341",
    forty: "\u56DB\u5341",
    fifty: "\u4E94\u5341",
    sixty: "\u516D\u5341",
    seventy: "\u4E03\u5341",
    eighty: "\u516B\u5341",
    ninety: "\u4E5D\u5341",
    "one hundred": "\u767E",
    morning: "\u671D",
    afternoon: "\u5348\u5F8C",
    evening: "\u5915\u65B9",
    night: "\u591C",
    monday: "\u6708\u66DC\u65E5",
    tuesday: "\u706B\u66DC\u65E5",
    wednesday: "\u6C34\u66DC\u65E5",
    thursday: "\u6728\u66DC\u65E5",
    friday: "\u91D1\u66DC\u65E5",
    saturday: "\u571F\u66DC\u65E5",
    sunday: "\u65E5\u66DC\u65E5",
    january: "1\u6708",
    february: "2\u6708",
    march: "3\u6708",
    april: "4\u6708",
    may: "5\u6708",
    june: "6\u6708",
    july: "7\u6708",
    august: "8\u6708",
    september: "9\u6708",
    october: "10\u6708",
    november: "11\u6708",
    december: "12\u6708",
    food: "\u98DF\u3079\u7269",
    water: "\u6C34",
    bread: "\u30D1\u30F3",
    meat: "\u8089",
    chicken: "\u9D8F\u8089",
    fish: "\u9B5A",
    rice: "\u3054\u98EF",
    vegetable: "\u91CE\u83DC",
    fruit: "\u679C\u7269",
    egg: "\u5375",
    cheese: "\u30C1\u30FC\u30BA",
    milk: "\u725B\u4E73",
    coffee: "\u30B3\u30FC\u30D2\u30FC",
    tea: "\u304A\u8336",
    beer: "\u30D3\u30FC\u30EB",
    wine: "\u30EF\u30A4\u30F3",
    juice: "\u30B8\u30E5\u30FC\u30B9",
    salt: "\u5869",
    sugar: "\u7802\u7CD6",
    breakfast: "\u671D\u98DF",
    lunch: "\u663C\u98DF",
    dinner: "\u5915\u98DF",
    home: "\u5BB6",
    house: "\u5BB6",
    room: "\u90E8\u5C4B",
    kitchen: "\u53F0\u6240",
    bathroom: "\u6D74\u5BA4",
    bedroom: "\u5BDD\u5BA4",
    table: "\u30C6\u30FC\u30D6\u30EB",
    chair: "\u6905\u5B50",
    door: "\u30C9\u30A2",
    window: "\u7A93",
    bed: "\u30D9\u30C3\u30C9",
    lamp: "\u30E9\u30F3\u30D7",
    key: "\u9375",
    bag: "\u304B\u3070\u3093",
    wallet: "\u8CA1\u5E03",
    phone: "\u96FB\u8A71",
    computer: "\u30B3\u30F3\u30D4\u30E5\u30FC\u30BF\u30FC",
    charger: "\u5145\u96FB\u5668",
    book: "\u672C",
    pen: "\u30DA\u30F3",
    pencil: "\u925B\u7B46",
    paper: "\u7D19",
    school: "\u5B66\u6821",
    work: "\u4ED5\u4E8B",
    teacher: "\u5148\u751F",
    student: "\u5B66\u751F",
    class: "\u6388\u696D",
    office: "\u30AA\u30D5\u30A3\u30B9",
    meeting: "\u4F1A\u8B70",
    project: "\u30D7\u30ED\u30B8\u30A7\u30AF\u30C8",
    email: "\u30E1\u30FC\u30EB",
    friend: "\u53CB\u3060\u3061",
    family: "\u5BB6\u65CF",
    mother: "\u6BCD",
    father: "\u7236",
    brother: "\u5144\u5F1F",
    sister: "\u59C9\u59B9",
    mom: "\u304A\u6BCD\u3055\u3093",
    dad: "\u304A\u7236\u3055\u3093",
    grandfather: "\u7956\u7236",
    grandmother: "\u7956\u6BCD",
    daughter: "\u5A18",
    son: "\u606F\u5B50",
    child: "\u5B50\u3069\u3082",
    baby: "\u8D64\u3061\u3083\u3093",
    boy: "\u7537\u306E\u5B50",
    girl: "\u5973\u306E\u5B50",
    person: "\u4EBA",
    man: "\u7537\u6027",
    woman: "\u5973\u6027",
    doctor: "\u533B\u8005",
    nurse: "\u770B\u8B77\u5E2B",
    patient: "\u60A3\u8005",
    car: "\u8ECA",
    bus: "\u30D0\u30B9",
    taxi: "\u30BF\u30AF\u30B7\u30FC",
    train: "\u96FB\u8ECA",
    subway: "\u5730\u4E0B\u9244",
    airport: "\u7A7A\u6E2F",
    station: "\u99C5",
    hotel: "\u30DB\u30C6\u30EB",
    map: "\u5730\u56F3",
    ticket: "\u5207\u7B26",
    entrance: "\u5165\u53E3",
    exit: "\u51FA\u53E3",
    street: "\u901A\u308A",
    corner: "\u89D2",
    here: "\u3053\u3053",
    there: "\u305D\u3053",
    left: "\u5DE6",
    right: "\u53F3",
    straight: "\u307E\u3063\u3059\u3050",
    near: "\u8FD1\u3044",
    far: "\u9060\u3044",
    money: "\u304A\u91D1",
    price: "\u5024\u6BB5",
    store: "\u5E97",
    market: "\u5E02\u5834",
    receipt: "\u30EC\u30B7\u30FC\u30C8",
    cash: "\u73FE\u91D1",
    card: "\u30AB\u30FC\u30C9",
    clothes: "\u670D",
    shirt: "\u30B7\u30E3\u30C4",
    pants: "\u30BA\u30DC\u30F3",
    shoes: "\u9774",
    dress: "\u30EF\u30F3\u30D4\u30FC\u30B9",
    jacket: "\u30B8\u30E3\u30B1\u30C3\u30C8",
    size: "\u30B5\u30A4\u30BA",
    color: "\u8272",
    red: "\u8D64",
    blue: "\u9752",
    green: "\u7DD1",
    yellow: "\u9EC4\u8272",
    black: "\u9ED2",
    white: "\u767D",
    gray: "\u7070\u8272",
    brown: "\u8336\u8272",
    purple: "\u7D2B",
    pink: "\u30D4\u30F3\u30AF",
    orange: "\u30AA\u30EC\u30F3\u30B8",
    body: "\u4F53",
    head: "\u982D",
    face: "\u9854",
    hand: "\u624B",
    arm: "\u8155",
    leg: "\u811A",
    foot: "\u8DB3",
    eye: "\u76EE",
    mouth: "\u53E3",
    nose: "\u9F3B",
    heart: "\u5FC3",
    stomach: "\u304A\u8179",
    hot: "\u6691\u3044",
    cold: "\u5BD2\u3044",
    happy: "\u3046\u308C\u3057\u3044",
    sad: "\u60B2\u3057\u3044",
    tired: "\u75B2\u308C\u305F",
    sick: "\u5177\u5408\u304C\u60AA\u3044",
    angry: "\u6012\u3063\u3066\u3044\u308B",
    relaxed: "\u843D\u3061\u7740\u3044\u305F",
    big: "\u5927\u304D\u3044",
    small: "\u5C0F\u3055\u3044",
    good: "\u826F\u3044",
    bad: "\u60AA\u3044",
    new: "\u65B0\u3057\u3044",
    old: "\u53E4\u3044",
    expensive: "\u9AD8\u3044",
    cheap: "\u5B89\u3044",
    open: "\u958B\u3044\u3066\u3044\u308B",
    closed: "\u9589\u307E\u3063\u3066\u3044\u308B",
    buy: "\u8CB7\u3046",
    pay: "\u6255\u3046",
    travel: "\u65C5\u884C\u3059\u308B",
    relax: "\u304F\u3064\u308D\u3050",
    complaint: "\u82E6\u60C5",
    help: "\u52A9\u3051",
    weather: "\u5929\u6C17",
    rain: "\u96E8",
    sun: "\u592A\u967D",
    wind: "\u98A8",
    cloud: "\u96F2",
    technology: "\u30C6\u30AF\u30CE\u30ED\u30B8\u30FC",
    internet: "\u30A4\u30F3\u30BF\u30FC\u30CD\u30C3\u30C8",
    app: "\u30A2\u30D7\u30EA",
    camera: "\u30AB\u30E1\u30E9",
    music: "\u97F3\u697D",
    movie: "\u6620\u753B",
    art: "\u82B8\u8853",
    history: "\u6B74\u53F2",
    science: "\u79D1\u5B66",
    society: "\u793E\u4F1A",
    culture: "\u6587\u5316",
    environment: "\u74B0\u5883",
    policy: "\u65B9\u91DD",
    truth: "\u771F\u5B9F",
    problem: "\u554F\u984C",
    solution: "\u89E3\u6C7A\u7B56",
    idea: "\u8003\u3048",
    opinion: "\u610F\u898B",
    reason: "\u7406\u7531",
    plan: "\u8A08\u753B",
    dream: "\u5922",
    success: "\u6210\u529F",
    failure: "\u5931\u6557",
    change: "\u5909\u5316",
    choice: "\u9078\u629E",
    skill: "\u6280\u80FD",
    knowledge: "\u77E5\u8B58",
    language: "\u8A00\u8A9E",
    communication: "\u30B3\u30DF\u30E5\u30CB\u30B1\u30FC\u30B7\u30E7\u30F3",
    relationship: "\u95A2\u4FC2",
    community: "\u5171\u540C\u4F53",
    leadership: "\u30EA\u30FC\u30C0\u30FC\u30B7\u30C3\u30D7",
    ubiquitous: "\u81F3\u308B\u6240\u306B\u3042\u308B",
    quintessential: "\u5178\u578B\u7684\u306A",
    esoteric: "\u96E3\u89E3\u306A",
    ephemeral: "\u306F\u304B\u306A\u3044",
    serendipity: "\u601D\u3044\u304C\u3051\u306A\u3044\u5E78\u904B",
    paradigm: "\u67A0\u7D44\u307F",
    juxtaposition: "\u4E26\u7F6E",
    cognizant: "\u3088\u304F\u7406\u89E3\u3057\u3066\u3044\u308B",
    conundrum: "\u96E3\u554F",
    intrinsic: "\u672C\u8CEA\u7684\u306A",
    ambivalent: "\u8907\u96D1\u306A\u6C17\u6301\u3061\u306E",
    scrutinize: "\u8A73\u3057\u304F\u8ABF\u3079\u308B",
    alleviate: "\u548C\u3089\u3052\u308B",
    perpetuate: "\u9577\u5F15\u304B\u305B\u308B",
    superfluous: "\u4F59\u5206\u306A",
    delineate: "\u660E\u78BA\u306B\u793A\u3059",
    exacerbate: "\u60AA\u5316\u3055\u305B\u308B",
    dichotomy: "\u4E8C\u5206\u6CD5",
    epitome: "\u5178\u578B",
    proliferate: "\u6025\u5897\u3059\u308B"
  };
  Object.assign(WORD_TRANSLATIONS, {
    absolutely: "\u7D76\u5BFE\u306B",
    accordingly: "\u305D\u308C\u306B\u5FDC\u3058\u3066",
    achievement: "\u9054\u6210",
    acquire: "\u8EAB\u306B\u3064\u3051\u308B",
    activism: "\u793E\u4F1A\u904B\u52D5",
    actually: "\u5B9F\u306F",
    address: "\u4F4F\u6240",
    admittedly: "\u305F\u3057\u304B\u306B",
    agreement: "\u5408\u610F",
    allergy: "\u30A2\u30EC\u30EB\u30AE\u30FC",
    ambiguous: "\u66D6\u6627\u306A",
    animal: "\u52D5\u7269",
    anxious: "\u4E0D\u5B89\u306A",
    anyway: "\u3068\u306B\u304B\u304F",
    apartment: "\u30A2\u30D1\u30FC\u30C8",
    appetizer: "\u524D\u83DC",
    appointment: "\u7D04\u675F",
    arbitrary: "\u6063\u610F\u7684\u306A",
    articulate: "\u660E\u78BA\u306B\u8868\u73FE\u3059\u308B",
    ashamed: "\u6065\u305A\u304B\u3057\u3044",
    aunt: "\u304A\u3070",
    backpack: "\u30D0\u30C3\u30AF\u30D1\u30C3\u30AF",
    be: "\u3067\u3042\u308B",
    beach: "\u6D77\u8FBA",
    beautiful: "\u7F8E\u3057\u3044",
    beauty: "\u7F8E\u3057\u3055",
    bored: "\u9000\u5C48\u306A",
    boss: "\u4E0A\u53F8",
    boyfriend: "\u30DC\u30FC\u30A4\u30D5\u30EC\u30F3\u30C9",
    budget: "\u4E88\u7B97",
    calm: "\u843D\u3061\u7740\u3044\u305F",
    can: "\u3067\u304D\u308B",
    cancel: "\u30AD\u30E3\u30F3\u30BB\u30EB\u3059\u308B",
    ceiling: "\u5929\u4E95",
    celebration: "\u304A\u795D\u3044",
    chef: "\u30B7\u30A7\u30D5",
    clean: "\u6E05\u6F54\u306A",
    clearly: "\u306F\u3063\u304D\u308A\u8A00\u3048\u3070",
    client: "\u9867\u5BA2",
    coat: "\u30B3\u30FC\u30C8",
    colleague: "\u540C\u50DA",
    come: "\u6765\u308B",
    comfortable: "\u5FEB\u9069\u306A",
    comprehend: "\u7406\u89E3\u3059\u308B",
    concerning: "\u301C\u306B\u95A2\u3057\u3066\u306F",
    confirm: "\u78BA\u8A8D\u3059\u308B",
    confused: "\u6DF7\u4E71\u3057\u305F",
    consequently: "\u305D\u306E\u7D50\u679C",
    contemplate: "\u719F\u8003\u3059\u308B",
    contract: "\u5951\u7D04",
    conversely: "\u9006\u306B\u8A00\u3048\u3070",
    cool: "\u6DBC\u3057\u3044",
    cough: "\u305B\u304D",
    cousin: "\u3044\u3068\u3053",
    creativity: "\u5275\u9020\u6027",
    crime: "\u72AF\u7F6A",
    customs: "\u7A0E\u95A2",
    dance: "\u8E0A\u308B",
    dangerous: "\u5371\u967A\u306A",
    date: "\u65E5\u4ED8",
    deadline: "\u7DE0\u3081\u5207\u308A",
    degree: "\u5EA6",
    delay: "\u9045\u5EF6",
    delicious: "\u304A\u3044\u3057\u3044",
    democracy: "\u6C11\u4E3B\u4E3B\u7FA9",
    demonstrate: "\u793A\u3059",
    dessert: "\u30C7\u30B6\u30FC\u30C8",
    destination: "\u76EE\u7684\u5730",
    difficult: "\u96E3\u3057\u3044",
    difficulty: "\u96E3\u3057\u3055",
    dirty: "\u6C5A\u3044",
    disappointed: "\u304C\u3063\u304B\u308A\u3057\u305F",
    discrimination: "\u5DEE\u5225",
    dish: "\u6599\u7406",
    divorced: "\u96E2\u5A5A\u3057\u305F",
    do: "\u3059\u308B",
    double: "\u4E8C\u500D",
    drink: "\u98F2\u3080",
    easy: "\u7C21\u5358\u306A",
    eat: "\u98DF\u3079\u308B",
    economy: "\u7D4C\u6E08",
    education: "\u6559\u80B2",
    eloquent: "\u96C4\u5F01\u306A",
    emergency: "\u7DCA\u6025\u4E8B\u614B",
    emotion: "\u611F\u60C5",
    employee: "\u5F93\u696D\u54E1",
    engineer: "\u30A8\u30F3\u30B8\u30CB\u30A2",
    equality: "\u5E73\u7B49",
    error: "\u8AA4\u308A",
    ethics: "\u502B\u7406",
    event: "\u51FA\u6765\u4E8B",
    exactly: "\u305D\u306E\u901A\u308A",
    excited: "\u308F\u304F\u308F\u304F\u3057\u305F",
    excursion: "\u5C0F\u65C5\u884C",
    exhibition: "\u5C55\u793A\u4F1A",
    experience: "\u7D4C\u9A13",
    facilitate: "\u4FC3\u9032\u3059\u308B",
    faith: "\u4FE1\u5FF5",
    fall: "\u79CB",
    fast: "\u901F\u3044",
    fat: "\u592A\u3063\u305F",
    feel: "\u611F\u3058\u308B",
    feminism: "\u30D5\u30A7\u30DF\u30CB\u30BA\u30E0",
    fever: "\u71B1",
    first: "\u6700\u521D",
    fix: "\u76F4\u3059",
    flight: "\u30D5\u30E9\u30A4\u30C8",
    floor: "\u5E8A",
    flower: "\u82B1",
    flu: "\u30A4\u30F3\u30D5\u30EB\u30A8\u30F3\u30B6",
    freedom: "\u81EA\u7531",
    friendly: "\u89AA\u3057\u307F\u3084\u3059\u3044",
    frustrated: "\u3044\u3089\u7ACB\u3063\u305F",
    fun: "\u697D\u3057\u3055",
    funny: "\u9762\u767D\u3044",
    furniture: "\u5BB6\u5177",
    furthermore: "\u3055\u3089\u306B",
    gallery: "\u753B\u5ECA",
    game: "\u30B2\u30FC\u30E0",
    gathering: "\u96C6\u307E\u308A",
    girlfriend: "\u30AC\u30FC\u30EB\u30D5\u30EC\u30F3\u30C9",
    give: "\u4E0E\u3048\u308B",
    glasses: "\u773C\u93E1",
    go: "\u884C\u304F",
    goal: "\u76EE\u6A19",
    government: "\u653F\u5E9C",
    granted: "\u305F\u3057\u304B\u306B",
    grateful: "\u611F\u8B1D\u3057\u3066\u3044\u308B",
    guide: "\u30AC\u30A4\u30C9",
    half: "\u534A\u5206",
    handsome: "\u30CF\u30F3\u30B5\u30E0\u306A",
    hat: "\u5E3D\u5B50",
    hate: "\u5ACC\u3046",
    have: "\u6301\u3063\u3066\u3044\u308B",
    headache: "\u982D\u75DB",
    healthcare: "\u533B\u7642",
    hence: "\u3057\u305F\u304C\u3063\u3066",
    hobby: "\u8DA3\u5473",
    homesick: "\u30DB\u30FC\u30E0\u30B7\u30C3\u30AF",
    hope: "\u5E0C\u671B",
    hospital: "\u75C5\u9662",
    however: "\u3057\u304B\u3057",
    hungry: "\u7A7A\u8179\u306A",
    husband: "\u592B",
    imagination: "\u60F3\u50CF\u529B",
    immigration: "\u5165\u56FD\u5BE9\u67FB",
    implement: "\u5B9F\u884C\u3059\u308B",
    inequality: "\u4E0D\u5E73\u7B49",
    ingredient: "\u6750\u6599",
    inherent: "\u56FA\u6709\u306E",
    injury: "\u3051\u304C",
    innovative: "\u9769\u65B0\u7684\u306A",
    insurance: "\u4FDD\u967A",
    intelligence: "\u77E5\u6027",
    interested: "\u8208\u5473\u304C\u3042\u308B",
    invite: "\u62DB\u5F85\u3059\u308B",
    issue: "\u554F\u984C",
    itinerary: "\u65C5\u7A0B",
    jealous: "\u5AC9\u59AC\u3057\u3066\u3044\u308B",
    job: "\u4ED5\u4E8B",
    journey: "\u65C5",
    justice: "\u6B63\u7FA9",
    kind: "\u89AA\u5207\u306A",
    know: "\u77E5\u3063\u3066\u3044\u308B",
    lake: "\u6E56",
    lawyer: "\u5F01\u8B77\u58EB",
    like: "\u597D\u3080",
    listen: "\u805E\u304F",
    lonely: "\u5B64\u72EC\u306A",
    loud: "\u3046\u308B\u3055\u3044",
    love: "\u611B",
    luckily: "\u5E78\u904B\u306B\u3082",
    luggage: "\u8377\u7269",
    make: "\u4F5C\u308B",
    manager: "\u7BA1\u7406\u8077",
    married: "\u7D50\u5A5A\u3057\u3066\u3044\u308B",
    mean: "\u610F\u5730\u60AA\u306A",
    medicine: "\u85AC",
    memory: "\u8A18\u61B6",
    meticulous: "\u51E0\u5E33\u9762\u306A",
    mistake: "\u9593\u9055\u3044",
    moment: "\u77AC\u9593",
    morality: "\u9053\u5FB3",
    moreover: "\u305D\u306E\u3046\u3048",
    mountain: "\u5C71",
    museum: "\u535A\u7269\u9928",
    need: "\u5FC5\u8981\u3068\u3059\u308B",
    negotiate: "\u4EA4\u6E09\u3059\u308B",
    nervous: "\u7DCA\u5F35\u3057\u305F",
    nevertheless: "\u305D\u308C\u3067\u3082",
    nonetheless: "\u305D\u308C\u306B\u3082\u304B\u304B\u308F\u3089\u305A",
    notwithstanding: "\u305D\u308C\u306B\u3082\u304B\u304B\u308F\u3089\u305A",
    objective: "\u76EE\u7684",
    obviously: "\u660E\u3089\u304B\u306B",
    pain: "\u75DB\u307F",
    parent: "\u89AA",
    party: "\u30D1\u30FC\u30C6\u30A3\u30FC",
    passport: "\u30D1\u30B9\u30DD\u30FC\u30C8",
    peace: "\u5E73\u548C",
    perceive: "\u8A8D\u8B58\u3059\u308B",
    performance: "\u6210\u679C",
    pharmacy: "\u85AC\u5C40",
    photo: "\u5199\u771F",
    play: "\u904A\u3076",
    police: "\u8B66\u5BDF",
    politics: "\u653F\u6CBB",
    pollution: "\u6C5A\u67D3",
    portion: "\u91CF",
    poverty: "\u8CA7\u56F0",
    pragmatic: "\u5B9F\u7528\u7684\u306A",
    prescription: "\u51E6\u65B9\u7B8B",
    pretty: "\u304B\u308F\u3044\u3044",
    probably: "\u304A\u305D\u3089\u304F",
    profound: "\u6DF1\u3044",
    proud: "\u8A87\u3089\u3057\u3044",
    racism: "\u4EBA\u7A2E\u5DEE\u5225",
    read: "\u8AAD\u3080",
    reality: "\u73FE\u5B9F",
    recommendation: "\u304A\u3059\u3059\u3081",
    refund: "\u8FD4\u91D1",
    relatives: "\u89AA\u621A",
    reluctant: "\u6C17\u304C\u9032\u307E\u306A\u3044",
    rent: "\u5BB6\u8CC3",
    repair: "\u4FEE\u7406\u3059\u308B",
    replace: "\u4EA4\u63DB\u3059\u308B",
    reservation: "\u4E88\u7D04",
    resilient: "\u7ACB\u3061\u76F4\u308A\u306E\u65E9\u3044",
    responsibility: "\u8CAC\u4EFB",
    river: "\u5DDD",
    run: "\u8D70\u308B",
    safe: "\u5B89\u5168\u306A",
    salary: "\u7D66\u6599",
    schedule: "\u4E88\u5B9A",
    season: "\u5B63\u7BC0",
    second: "\u4E8C\u756A\u76EE",
    see: "\u898B\u308B",
    serious: "\u771F\u9762\u76EE\u306A",
    short: "\u77ED\u3044",
    significant: "\u91CD\u8981\u306A",
    single: "\u72EC\u8EAB\u306E",
    skirt: "\u30B9\u30AB\u30FC\u30C8",
    sleep: "\u7720\u308B",
    slow: "\u9045\u3044",
    smart: "\u8CE2\u3044",
    snow: "\u96EA",
    socks: "\u9774\u4E0B",
    sofa: "\u30BD\u30D5\u30A1",
    speak: "\u8A71\u3059",
    sport: "\u30B9\u30DD\u30FC\u30C4",
    spring: "\u6625",
    stomachache: "\u8179\u75DB",
    storm: "\u5D50",
    story: "\u7269\u8A9E",
    strategy: "\u6226\u7565",
    stressed: "\u30B9\u30C8\u30EC\u30B9\u3092\u611F\u3058\u305F",
    strong: "\u5F37\u3044",
    stupid: "\u611A\u304B\u306A",
    subsequently: "\u305D\u306E\u5F8C",
    substantial: "\u304B\u306A\u308A\u306E",
    suitcase: "\u30B9\u30FC\u30C4\u30B1\u30FC\u30B9",
    summer: "\u590F",
    surprised: "\u9A5A\u3044\u305F",
    swim: "\u6CF3\u3050",
    symptom: "\u75C7\u72B6",
    take: "\u53D6\u308B",
    tall: "\u80CC\u304C\u9AD8\u3044",
    temperature: "\u6C17\u6E29",
    therefore: "\u3057\u305F\u304C\u3063\u3066",
    thin: "\u7D30\u3044",
    third: "\u4E09\u756A\u76EE",
    thirsty: "\u5589\u304C\u6E07\u3044\u305F",
    thus: "\u3053\u306E\u3088\u3046\u306B",
    tourist: "\u89B3\u5149\u5BA2",
    towel: "\u30BF\u30AA\u30EB",
    tree: "\u6728",
    trip: "\u65C5\u884C",
    trouble: "\u30C8\u30E9\u30D6\u30EB",
    tv: "\u30C6\u30EC\u30D3",
    ugly: "\u919C\u3044",
    uncle: "\u304A\u3058",
    uncomfortable: "\u5C45\u5FC3\u5730\u304C\u60AA\u3044",
    understand: "\u7406\u89E3\u3059\u308B",
    unemployment: "\u5931\u696D",
    unfortunately: "\u6B8B\u5FF5\u306A\u304C\u3089",
    vacation: "\u4F11\u6687",
    vegan: "\u30F4\u30A3\u30FC\u30AC\u30F3",
    violence: "\u66B4\u529B",
    visa: "\u30D3\u30B6",
    waiter: "\u7D66\u4ED5",
    walk: "\u6B69\u304F",
    wall: "\u58C1",
    want: "\u6B32\u3057\u3044",
    war: "\u6226\u4E89",
    warm: "\u6696\u304B\u3044",
    watch: "\u898B\u308B",
    weak: "\u5F31\u3044",
    weekend: "\u9031\u672B",
    whereas: "\u4E00\u65B9\u3067",
    whereby: "\u305D\u308C\u306B\u3088\u3063\u3066",
    wife: "\u59BB",
    winter: "\u51AC",
    wisdom: "\u77E5\u6075",
    worried: "\u5FC3\u914D\u3057\u3066\u3044\u308B",
    wound: "\u50B7",
    young: "\u82E5\u3044"
  });

  // ../nosabos/nosabos/src/data/flashcards/portugueseLocalizer.js
  var normalizeKey = (value) => String(value || "").trim().replace(/[¿¡]/g, "").replace(/\s+/g, " ").toLocaleLowerCase("es-ES");
  var PORTUGUESE_FLASHCARD_EXACT = {
    [normalizeKey("Hola")]: "ol\xE1",
    [normalizeKey("Adi\xF3s")]: "tchau",
    [normalizeKey("Gracias")]: "obrigado",
    [normalizeKey("Disculpe")]: "com licen\xE7a",
    [normalizeKey("Lo siento")]: "desculpe",
    [normalizeKey("\xBFC\xF3mo est\xE1s?")]: "como voc\xEA est\xE1?",
    [normalizeKey("Mucho gusto")]: "prazer",
    [normalizeKey("De nada")]: "de nada",
    [normalizeKey("Buenos d\xEDas")]: "bom dia",
    [normalizeKey("Buenas tardes")]: "boa tarde",
    [normalizeKey("Buenas noches")]: "boa noite",
    [normalizeKey("\xBFQu\xE9 tal?")]: "como vai?",
    [normalizeKey("\xBFQu\xE9 pasa?")]: "o que est\xE1 acontecendo?",
    [normalizeKey("Felicidades")]: "parab\xE9ns",
    [normalizeKey("Feliz cumplea\xF1os")]: "feliz anivers\xE1rio",
    [normalizeKey("Feliz Navidad")]: "feliz Natal",
    [normalizeKey("Feliz A\xF1o Nuevo")]: "feliz ano novo",
    [normalizeKey("Bienvenido")]: "bem-vindo",
    [normalizeKey("Perd\xF3n")]: "perd\xE3o",
    [normalizeKey("Hasta pronto")]: "at\xE9 breve",
    [normalizeKey("Hasta ma\xF1ana")]: "at\xE9 amanh\xE3",
    [normalizeKey("Me llamo...")]: "meu nome \xE9...",
    [normalizeKey("Soy de...")]: "sou de...",
    [normalizeKey("Tengo X a\xF1os")]: "tenho X anos",
    [normalizeKey("\xBFC\xF3mo te llamas?")]: "como voc\xEA se chama?",
    [normalizeKey("\xBFDe d\xF3nde eres?")]: "de onde voc\xEA \xE9?",
    [normalizeKey("\xBFCu\xE1ntos a\xF1os tienes?")]: "quantos anos voc\xEA tem?",
    [normalizeKey("Este es mi amigo...")]: "este \xE9 meu amigo...",
    [normalizeKey("Vivo en...")]: "moro em...",
    [normalizeKey("Hablo...")]: "falo...",
    [normalizeKey("\xBFHablas ingl\xE9s?")]: "voc\xEA fala ingl\xEAs?",
    [normalizeKey("\xBFCu\xE1nto?")]: "quanto?",
    [normalizeKey("Muy caro")]: "muito caro",
    [normalizeKey("Dos, por favor")]: "dois, por favor",
    [normalizeKey("\xBFQu\xE9 hora es?")]: "que horas s\xE3o?",
    [normalizeKey("\xBFA qu\xE9 hora?")]: "a que horas?",
    [normalizeKey("\xBFQu\xE9 d\xEDa es hoy?")]: "que dia \xE9 hoje?",
    [normalizeKey("\xBFQu\xE9 es esto?")]: "o que \xE9 isto?",
    [normalizeKey("\xBFD\xF3nde est\xE1...?")]: "onde fica...?",
    [normalizeKey("\xBFCu\xE1ndo abre?")]: "quando abre?",
    [normalizeKey("\xBFQui\xE9n es?")]: "quem \xE9?",
    [normalizeKey("\xBFPor qu\xE9?")]: "por qu\xEA?",
    [normalizeKey("\xBFC\xF3mo llego a...?")]: "como chego a...?",
    [normalizeKey("\xBFCu\xE1nto cuesta?")]: "quanto custa?",
    [normalizeKey("\xBFCu\xE1nto tiempo?")]: "quanto tempo?",
    [normalizeKey("\xBFQu\xE9 tan lejos?")]: "qu\xE3o longe?",
    [normalizeKey("\xBFPuedes ayudarme?")]: "voc\xEA pode me ajudar?",
    [normalizeKey("\xBFPuedo...?")]: "posso...?",
    [normalizeKey("\xBFHay...?")]: "h\xE1...?",
    [normalizeKey("\xBFTienes...?")]: "voc\xEA tem...?",
    [normalizeKey("Quisiera...")]: "eu gostaria de...",
    [normalizeKey("Tengo hambre")]: "estou com fome",
    [normalizeKey("Tengo sed")]: "estou com sede",
    [normalizeKey("La cuenta, por favor")]: "a conta, por favor",
    [normalizeKey("Una mesa para dos")]: "uma mesa para dois",
    [normalizeKey("El men\xFA, por favor")]: "o card\xE1pio, por favor",
    [normalizeKey("\xA1Salud!")]: "sa\xFAde!",
    [normalizeKey("Buen provecho")]: "bom apetite",
    [normalizeKey("Est\xE1 delicioso")]: "est\xE1 delicioso",
    [normalizeKey("Sin hielo, por favor")]: "sem gelo, por favor",
    [normalizeKey("Para llevar")]: "para viagem",
    [normalizeKey("M\xE1s pan, por favor")]: "mais p\xE3o, por favor",
    [normalizeKey("Agua, por favor")]: "\xE1gua, por favor",
    [normalizeKey("\xBFD\xF3nde est\xE1 el ba\xF1o?")]: "onde fica o banheiro?",
    [normalizeKey("Gira a la izquierda")]: "vire \xE0 esquerda",
    [normalizeKey("Gira a la derecha")]: "vire \xE0 direita",
    [normalizeKey("Sigue recto")]: "siga em frente",
    [normalizeKey("Est\xE1 cerca")]: "fica perto",
    [normalizeKey("Est\xE1 lejos")]: "fica longe",
    [normalizeKey("Pare aqu\xED, por favor")]: "pare aqui, por favor",
    [normalizeKey("Ll\xE9veme a...")]: "leve-me para...",
    [normalizeKey("\xBFCu\xE1nto cuesta a...?")]: "quanto custa at\xE9...?",
    [normalizeKey("Un boleto, por favor")]: "uma passagem, por favor",
    [normalizeKey("\xBFA qu\xE9 hora sale?")]: "a que horas sai?",
    [normalizeKey("Me lo llevo")]: "vou levar",
    [normalizeKey("\xBFAceptan tarjetas de cr\xE9dito?")]: "voc\xEAs aceitam cart\xF5es de cr\xE9dito?",
    [normalizeKey("\xBFPuedo pagar con...?")]: "posso pagar com...?",
    [normalizeKey("\xBFHay descuento?")]: "h\xE1 desconto?",
    [normalizeKey("Solo estoy mirando")]: "s\xF3 estou olhando",
    [normalizeKey("\xBFQu\xE9 talla?")]: "qual tamanho?",
    [normalizeKey("\xBFPuedo prob\xE1rmelo?")]: "posso experimentar?",
    [normalizeKey("Recibo, por favor")]: "recibo, por favor",
    [normalizeKey("Tengo una reserva")]: "tenho uma reserva",
    [normalizeKey("\xBFPor cu\xE1ntas noches?")]: "por quantas noites?",
    [normalizeKey("\xBFPuedo ver la habitaci\xF3n?")]: "posso ver o quarto?",
    [normalizeKey("Necesito m\xE1s toallas")]: "preciso de mais toalhas",
    [normalizeKey("\xA1Necesito ayuda!")]: "preciso de ajuda!",
    [normalizeKey("Llame a la polic\xEDa")]: "chame a pol\xEDcia",
    [normalizeKey("Estoy perdido")]: "estou perdido",
    [normalizeKey("No me siento bien")]: "n\xE3o estou me sentindo bem",
    [normalizeKey("\xBFD\xF3nde est\xE1 el hospital?")]: "onde fica o hospital?",
    [normalizeKey("Necesito un doctor")]: "preciso de um m\xE9dico",
    [normalizeKey("Me duele aqu\xED")]: "d\xF3i aqui",
    [normalizeKey("Ser/Estar")]: "ser/estar",
    [normalizeKey("Querer")]: "querer",
    [normalizeKey("Necesitar")]: "precisar",
    [normalizeKey("Tener")]: "ter",
    [normalizeKey("Ir")]: "ir",
    [normalizeKey("Venir")]: "vir",
    [normalizeKey("Ver")]: "ver",
    [normalizeKey("Hablar")]: "falar",
    [normalizeKey("Entender")]: "entender",
    [normalizeKey("Saber")]: "saber",
    [normalizeKey("Gustar")]: "gostar",
    [normalizeKey("Comer")]: "comer",
    [normalizeKey("Beber")]: "beber",
    [normalizeKey("Dormir")]: "dormir",
    [normalizeKey("Dar")]: "dar",
    [normalizeKey("Tomar")]: "tomar",
    [normalizeKey("Hacer")]: "fazer",
    [normalizeKey("Poder")]: "poder"
  };
  var PORTUGUESE_FLASHCARD_EN_EXACT = {
    [normalizeKey("Mom")]: "m\xE3e",
    [normalizeKey("Dad")]: "pai",
    [normalizeKey("Brother")]: "irm\xE3o",
    [normalizeKey("Sister")]: "irm\xE3",
    [normalizeKey("Grandfather")]: "av\xF4",
    [normalizeKey("Grandmother")]: "av\xF3",
    [normalizeKey("Baby")]: "beb\xEA",
    [normalizeKey("Boy")]: "menino",
    [normalizeKey("Girl")]: "menina",
    [normalizeKey("Person")]: "pessoa",
    [normalizeKey("Zero")]: "zero",
    [normalizeKey("One")]: "um",
    [normalizeKey("Two")]: "dois",
    [normalizeKey("Three")]: "tr\xEAs",
    [normalizeKey("Four")]: "quatro",
    [normalizeKey("Five")]: "cinco",
    [normalizeKey("Six")]: "seis",
    [normalizeKey("Seven")]: "sete",
    [normalizeKey("Eight")]: "oito",
    [normalizeKey("Nine")]: "nove",
    [normalizeKey("Ten")]: "dez",
    [normalizeKey("Morning")]: "manh\xE3",
    [normalizeKey("Tomorrow")]: "amanh\xE3",
    [normalizeKey("Yesterday")]: "ontem",
    [normalizeKey("Bye")]: "tchau",
    [normalizeKey("See you later")]: "at\xE9 logo",
    [normalizeKey("See you tomorrow")]: "at\xE9 amanh\xE3",
    [normalizeKey("Okay")]: "tudo bem",
    [normalizeKey("Help me please")]: "me ajude, por favor",
    [normalizeKey("With pleasure")]: "com prazer",
    [normalizeKey("Book")]: "livro",
    [normalizeKey("Car")]: "carro",
    [normalizeKey("Chair")]: "cadeira",
    [normalizeKey("Pen")]: "caneta",
    [normalizeKey("Pencil")]: "l\xE1pis",
    [normalizeKey("Phone")]: "telefone",
    [normalizeKey("Door")]: "porta",
    [normalizeKey("Window")]: "janela",
    [normalizeKey("Red")]: "vermelho",
    [normalizeKey("Orange")]: "laranja",
    [normalizeKey("Yellow")]: "amarelo",
    [normalizeKey("Purple")]: "roxo",
    [normalizeKey("Black")]: "preto",
    [normalizeKey("White")]: "branco",
    [normalizeKey("Brown")]: "marrom",
    [normalizeKey("Gray")]: "cinza",
    [normalizeKey("I")]: "eu",
    [normalizeKey("You")]: "voc\xEA",
    [normalizeKey("He")]: "ele",
    [normalizeKey("She")]: "ela",
    [normalizeKey("We")]: "n\xF3s",
    [normalizeKey("They")]: "eles",
    [normalizeKey("Near")]: "perto",
    [normalizeKey("Far")]: "longe",
    [normalizeKey("Street")]: "rua",
    [normalizeKey("The (masculine)")]: "o",
    [normalizeKey("The (feminine)")]: "a",
    [normalizeKey("Monday")]: "segunda-feira",
    [normalizeKey("Tuesday")]: "ter\xE7a-feira",
    [normalizeKey("Wednesday")]: "quarta-feira",
    [normalizeKey("Thursday")]: "quinta-feira",
    [normalizeKey("Friday")]: "sexta-feira",
    [normalizeKey("Sunday")]: "domingo",
    [normalizeKey("January")]: "janeiro",
    [normalizeKey("February")]: "fevereiro",
    [normalizeKey("March")]: "mar\xE7o",
    [normalizeKey("April")]: "abril",
    [normalizeKey("May")]: "maio",
    [normalizeKey("August")]: "agosto",
    [normalizeKey("June")]: "junho",
    [normalizeKey("July")]: "julho",
    [normalizeKey("September")]: "setembro",
    [normalizeKey("October")]: "outubro",
    [normalizeKey("November")]: "novembro",
    [normalizeKey("December")]: "dezembro",
    [normalizeKey("What")]: "o que",
    [normalizeKey("Why")]: "por qu\xEA",
    [normalizeKey("I am...")]: "sou...",
    [normalizeKey("This is...")]: "este \xE9...",
    [normalizeKey("Water")]: "\xE1gua",
    [normalizeKey("Wine")]: "vinho",
    [normalizeKey("Gluten-free")]: "sem gl\xFAten",
    [normalizeKey("Without...")]: "sem...",
    [normalizeKey("There")]: "ali",
    [normalizeKey("Straight")]: "reto",
    [normalizeKey("Exit")]: "sa\xEDda",
    [normalizeKey("Double")]: "dobro",
    [normalizeKey("I'm fine")]: "estou bem",
    [normalizeKey("No problem")]: "sem problema",
    [normalizeKey("Have a good day")]: "tenha um bom dia",
    [normalizeKey("Which")]: "qual",
    [normalizeKey("Right")]: "direita",
    [normalizeKey("Key")]: "chave",
    [normalizeKey("What's the Wi-Fi password?")]: "qual \xE9 a senha do Wi-Fi?",
    [normalizeKey("I'm learning")]: "estou aprendendo",
    [normalizeKey("Could you write it down?")]: "voc\xEA poderia escrever isso?",
    [normalizeKey("I think so")]: "acho que sim",
    [normalizeKey("I don't think so")]: "acho que n\xE3o",
    [normalizeKey("Whatever you prefer")]: "o que voc\xEA preferir",
    [normalizeKey("I'm not sure")]: "n\xE3o tenho certeza",
    [normalizeKey("I agree")]: "concordo",
    [normalizeKey("I disagree")]: "n\xE3o concordo",
    [normalizeKey("Are you married?")]: "voc\xEA \xE9 casado?",
    [normalizeKey("Manager")]: "gerente",
    [normalizeKey("I'm unemployed")]: "estou desempregado",
    [normalizeKey("I'm on vacation")]: "estou de f\xE9rias",
    [normalizeKey("I'm busy")]: "estou ocupado",
    [normalizeKey("I'm retired")]: "estou aposentado",
    [normalizeKey("Do you want to go to...?")]: "voc\xEA quer ir a...?",
    [normalizeKey("I'm here on vacation")]: "estou aqui de f\xE9rias",
    [normalizeKey("I'm here for business")]: "estou aqui a neg\xF3cios",
    [normalizeKey("How long are you staying?")]: "quanto tempo voc\xEA vai ficar?",
    [normalizeKey("Can I switch seats?")]: "posso trocar de assento?",
    [normalizeKey("Could you store this for me?")]: "voc\xEA poderia guardar isto para mim?",
    [normalizeKey("Is there a layover?")]: "h\xE1 escala?",
    [normalizeKey("I have nothing to declare")]: "n\xE3o tenho nada a declarar",
    [normalizeKey("I'm just passing through")]: "s\xF3 estou de passagem",
    [normalizeKey("Appointment")]: "compromisso",
    [normalizeKey("Date")]: "encontro",
    [normalizeKey("Do you have a room available?")]: "voc\xEAs t\xEAm um quarto dispon\xEDvel?",
    [normalizeKey("I have two children")]: "tenho dois filhos",
    [normalizeKey("Work")]: "trabalho",
    [normalizeKey("What time do you finish work?")]: "a que horas voc\xEA termina o trabalho?",
    [normalizeKey("I have a meeting")]: "tenho uma reuni\xE3o",
    [normalizeKey("I have a reservation under...")]: "tenho uma reserva em nome de...",
    [normalizeKey("Do you have a table available?")]: "voc\xEAs t\xEAm uma mesa dispon\xEDvel?",
    [normalizeKey("I have a problem")]: "tenho um problema",
    [normalizeKey("I have a fever")]: "estou com febre",
    [normalizeKey("I'm nauseous")]: "estou com n\xE1usea",
    [normalizeKey("Cash")]: "dinheiro",
    [normalizeKey("Card")]: "cart\xE3o",
    [normalizeKey("Towel")]: "toalha",
    [normalizeKey("Police")]: "pol\xEDcia",
    [normalizeKey("Pharmacy")]: "farm\xE1cia",
    [normalizeKey("Pain")]: "dor",
    [normalizeKey("Emergency")]: "emerg\xEAncia",
    [normalizeKey("I need to see a doctor")]: "preciso consultar um m\xE9dico",
    [normalizeKey("In practical terms...")]: "em termos pr\xE1ticos...",
    [normalizeKey("Technically speaking...")]: "tecnicamente falando...",
    [normalizeKey("One hundred")]: "cem",
    [normalizeKey("Fifteen")]: "quinze",
    [normalizeKey("Third")]: "terceiro",
    [normalizeKey("A quarter")]: "um quarto",
    [normalizeKey("A dozen")]: "uma d\xFAzia",
    [normalizeKey("In the afternoon")]: "\xE0 tarde",
    [normalizeKey("Burn the midnight oil")]: "trabalhar at\xE9 tarde",
    [normalizeKey("To some degree...")]: "at\xE9 certo ponto...",
    [normalizeKey("Want to come along?")]: "quer vir junto?",
    [normalizeKey("Sorry, I can't make it")]: "desculpe, n\xE3o vou conseguir",
    [normalizeKey("I'm busy that day")]: "estou ocupado nesse dia",
    [normalizeKey("A table for four, please")]: "uma mesa para quatro, por favor",
    [normalizeKey("What's the specialty?")]: "qual \xE9 a especialidade?",
    [normalizeKey("I can't eat...")]: "n\xE3o posso comer...",
    [normalizeKey("This isn't what I ordered")]: "isto n\xE3o \xE9 o que eu pedi",
    [normalizeKey("Keep the change")]: "fique com o troco",
    [normalizeKey("Complaint")]: "reclama\xE7\xE3o",
    [normalizeKey("There's a problem with...")]: "h\xE1 um problema com...",
    [normalizeKey("I want to file a complaint")]: "quero fazer uma reclama\xE7\xE3o",
    [normalizeKey("Can I speak to the manager?")]: "posso falar com o gerente?",
    [normalizeKey("I've never been to...")]: "nunca estive em...",
    [normalizeKey("I've never tried...")]: "nunca experimentei...",
    [normalizeKey("I'll never forget...")]: "nunca vou esquecer...",
    [normalizeKey("I'm grateful for...")]: "sou grato por...",
    [normalizeKey("I'm sick")]: "estou doente",
    [normalizeKey("I'm dizzy")]: "estou tonto",
    [normalizeKey("Can I make an appointment?")]: "posso marcar uma consulta?",
    [normalizeKey("Once in a blue moon")]: "de vez em quando",
    [normalizeKey("Better late than never")]: "antes tarde do que nunca",
    [normalizeKey("Actions speak louder than words")]: "a\xE7\xF5es falam mais alto que palavras",
    [normalizeKey("The early bird catches the worm")]: "quem cedo madruga, Deus ajuda",
    [normalizeKey("Every cloud has a silver lining")]: "h\xE1 males que v\xEAm para o bem",
    [normalizeKey("Bite off more than you can chew")]: "abra\xE7ar mais do que consegue",
    [normalizeKey("What's the status?")]: "qual \xE9 o status?",
    [normalizeKey("Could you send that in writing?")]: "voc\xEA poderia enviar isso por escrito?",
    [normalizeKey("Let's touch base")]: "vamos nos alinhar",
    [normalizeKey("I strongly believe that...")]: "acredito com firmeza que...",
    [normalizeKey("There's no doubt that...")]: "n\xE3o h\xE1 d\xFAvida de que...",
    [normalizeKey("It's obvious that...")]: "\xE9 \xF3bvio que...",
    [normalizeKey("I understand what you mean, but...")]: "entendo o que voc\xEA quer dizer, mas...",
    [normalizeKey("Studies show that...")]: "os estudos mostram que...",
    [normalizeKey("I'm not entirely sure")]: "n\xE3o tenho total certeza",
    [normalizeKey("If I had to guess...")]: "se eu tivesse que adivinhar...",
    [normalizeKey("There's a good chance that...")]: "h\xE1 uma boa chance de que...",
    [normalizeKey("It's unlikely that...")]: "\xE9 improv\xE1vel que...",
    [normalizeKey("What I'm trying to say is...")]: "o que estou tentando dizer \xE9...",
    [normalizeKey("The point I'm making is...")]: "o ponto que estou levantando \xE9...",
    [normalizeKey("Studies have shown that...")]: "os estudos mostraram que...",
    [normalizeKey("It has been demonstrated that...")]: "foi demonstrado que...",
    [normalizeKey("It is widely acknowledged that...")]: "\xE9 amplamente reconhecido que...",
    [normalizeKey("Scholars argue that...")]: "pesquisadores argumentam que...",
    [normalizeKey("The consensus is that...")]: "o consenso \xE9 que...",
    [normalizeKey("There is considerable debate about...")]: "h\xE1 um debate consider\xE1vel sobre...",
    [normalizeKey("It is worth noting that...")]: "vale destacar que...",
    [normalizeKey("It should be emphasized that...")]: "deve-se enfatizar que...",
    [normalizeKey("As far as X is concerned...")]: "no que diz respeito a X...",
    [normalizeKey("Wouldn't you agree that...?")]: "voc\xEA n\xE3o concordaria que...?",
    [normalizeKey("Surely you can see that...")]: "certamente voc\xEA pode ver que...",
    [normalizeKey("It goes without saying that...")]: "nem \xE9 preciso dizer que...",
    [normalizeKey("There's no denying that...")]: "n\xE3o h\xE1 como negar que...",
    [normalizeKey("It stands to reason that...")]: "\xE9 l\xF3gico que...",
    [normalizeKey("Logic dictates that...")]: "a l\xF3gica dita que...",
    [normalizeKey("Whereas...")]: "enquanto...",
    [normalizeKey("While it's true that...")]: "embora seja verdade que...",
    [normalizeKey("Whereby...")]: "por meio do qual...",
    [normalizeKey("Where there's smoke, there's fire")]: "onde h\xE1 fuma\xE7a, h\xE1 fogo",
    [normalizeKey("A picture is worth a thousand words")]: "uma imagem vale mais que mil palavras",
    [normalizeKey("The pen is mightier than the sword")]: "a caneta \xE9 mais poderosa que a espada",
    [normalizeKey("Two heads are better than one")]: "duas cabe\xE7as pensam melhor do que uma",
    [normalizeKey("Good things come to those who wait")]: "coisas boas chegam para quem espera",
    [normalizeKey("If you don't mind my saying...")]: "se voc\xEA n\xE3o se importar que eu diga...",
    [normalizeKey("I hope you won't take this the wrong way...")]: "espero que voc\xEA n\xE3o leve isto a mal..."
  };
  var SPANISH_LEAK_TOKENS = [
    "mam\xE1",
    "pap\xE1",
    "hermano",
    "hermana",
    "abuelo",
    "abuela",
    "beb\xE9",
    "ni\xF1o",
    "ni\xF1a",
    "persona",
    "cero",
    "uno",
    "tres",
    "cuatro",
    "siete",
    "ocho",
    "nueve",
    "diez",
    "once",
    "doce",
    "trece",
    "catorce",
    "diecis\xE9is",
    "diecisiete",
    "dieciocho",
    "diecinueve",
    "veinte",
    "treinta",
    "cuarenta",
    "cincuenta",
    "sesenta",
    "ochenta",
    "bueno",
    "malo",
    "m\xE1s o menos",
    "hasta luego",
    "hasta ma\xF1ana",
    "chao",
    "est\xE1 bien",
    "ay\xFAdame por favor",
    "con gusto",
    "soy",
    "bol\xEDgrafo",
    "l\xE1piz",
    "tel\xE9fono",
    "puerta",
    "ventana",
    "naranja",
    "rojo",
    "amarillo",
    "morado",
    "blanco",
    "marr\xF3n",
    "gris",
    "entiendo",
    "yo",
    "t\xFA",
    "ella",
    "nosotros",
    "ellos",
    "d\xF3nde",
    "qui\xE9n",
    "cu\xE1nto",
    "cu\xE1ntos",
    "cu\xE1ndo",
    "c\xF3mo",
    "pa\xEDs",
    "ciudad",
    "nacionalidad",
    "qu\xE9",
    "por qu\xE9",
    "ayer",
    "noche",
    "lunes",
    "martes",
    "mi\xE9rcoles",
    "jueves",
    "viernes",
    "enero",
    "febrero",
    "marzo",
    "mayo",
    "junio",
    "julio",
    "septiembre",
    "octubre",
    "noviembre",
    "diciembre",
    "pan",
    "pollo",
    "pescado",
    "huevo",
    "queso",
    "leche",
    "t\xE9",
    "cerveza",
    "jugo",
    "az\xFAcar",
    "caliente",
    "fr\xEDo",
    "agua",
    "izquierda",
    "derecha",
    "all\xED",
    "recto",
    "cerca",
    "lejos",
    "calle",
    "autob\xFAs",
    "tren",
    "aeropuerto",
    "ba\xF1o",
    "coche",
    "toalla",
    "tarjeta",
    "efectivo",
    "polic\xEDa",
    "farmacia",
    "dolor",
    "emergencia",
    "habitaci\xF3n",
    "reuni\xF3n",
    "trabajar",
    "trabajo",
    "hijos",
    "sin gluten",
    "sin...",
    "vino",
    "un cuarto",
    "una docena",
    "cien",
    "quince",
    "tercero",
    "por la tarde",
    "este es",
    "estoy",
    "podr\xEDas",
    "quieres",
    "cual",
    "llave",
    "queja",
    "nunca he",
    "os estudios muestran",
    "se ha demostrado",
    "una imagen",
    "la pluma",
    "lo siento",
    "hay escala",
    "de acuerdo",
    "hay un problema",
    "mientras que",
    "mediante el cual",
    "tengo una reserva a nome de",
    "tienen mesa disponible",
    "preciso ver a un doctor",
    "trabajar hasta tarde",
    "hasta cierto ponto"
  ];
  var escapeRegex = (value) => String(value || "").replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  var OBVIOUS_SPANISH_LEAK_PATTERN = new RegExp(
    `(?:^|[^\\p{L}\\p{M}])(?:${SPANISH_LEAK_TOKENS.map(escapeRegex).join("|")})(?=$|[^\\p{L}\\p{M}])`,
    "iu"
  );

  // ../nosabos/nosabos/src/data/flashcards/germanLocalizer.js
  var normalizeKey2 = (value) => String(value || "").trim().replace(/\s+/g, " ").toLowerCase();
  var CONCEPT_TRANSLATIONS = {
    "hello": "hallo",
    "goodbye": "auf Wiedersehen",
    "please": "bitte",
    "thank you": "danke",
    "excuse me": "entschuldigung",
    "sorry": "tut mir leid",
    "yes": "ja",
    "no": "nein",
    "maybe": "vielleicht",
    "how are you?": "wie geht es dir?",
    "nice to meet you": "sch\xF6n, dich kennenzulernen",
    "have a good day": "sch\xF6nen Tag",
    "see you later": "bis sp\xE4ter",
    "you're welcome": "gern geschehen",
    "i'm sorry": "es tut mir leid",
    "good morning": "guten Morgen",
    "good afternoon": "guten Nachmittag",
    "good evening": "guten Abend",
    "good night": "gute Nacht",
    "how's it going?": "wie l\xE4uft es?",
    "what's up?": "was geht?",
    "bless you": "gesundheit",
    "congratulations": "gl\xFCckwunsch",
    "happy birthday": "alles Gute zum Geburtstag",
    "merry christmas": "frohe Weihnachten",
    "happy new year": "frohes neues Jahr",
    "welcome": "willkommen",
    "pardon": "verzeihung",
    "see you soon": "bis bald",
    "see you tomorrow": "bis morgen",
    "name": "Name",
    "age": "Alter",
    "from": "aus",
    "where": "wo",
    "who": "wer",
    "i": "ich",
    "you": "du",
    "he": "er",
    "she": "sie",
    "we": "wir",
    "they": "sie",
    "my name is...": "ich hei\xDFe...",
    "i'm from...": "ich komme aus...",
    "i'm x years old": "ich bin X Jahre alt",
    "what's your name?": "wie hei\xDFt du?",
    "where are you from?": "woher kommst du?",
    "how old are you?": "wie alt bist du?",
    "this is my friend...": "das ist mein Freund...",
    "i live in...": "ich wohne in...",
    "i speak...": "ich spreche...",
    "do you speak english?": "sprichst du Englisch?",
    "country": "Land",
    "city": "Stadt",
    "language": "Sprache",
    "nationality": "Nationalit\xE4t",
    "zero": "Null",
    "one": "eins",
    "two": "zwei",
    "three": "drei",
    "four": "vier",
    "five": "f\xFCnf",
    "six": "sechs",
    "seven": "sieben",
    "eight": "acht",
    "nine": "neun",
    "ten": "zehn",
    "eleven": "elf",
    "twelve": "zw\xF6lf",
    "thirteen": "dreizehn",
    "fourteen": "vierzehn",
    "fifteen": "f\xFCnfzehn",
    "sixteen": "sechzehn",
    "seventeen": "siebzehn",
    "eighteen": "achtzehn",
    "nineteen": "neunzehn",
    "twenty": "zwanzig",
    "thirty": "drei\xDFig",
    "forty": "vierzig",
    "fifty": "f\xFCnfzig",
    "sixty": "sechzig",
    "seventy": "siebzig",
    "eighty": "achtzig",
    "ninety": "neunzig",
    "one hundred": "einhundert",
    "how much?": "wie viel?",
    "too expensive": "zu teuer",
    "one more": "noch eins",
    "two, please": "zwei, bitte",
    "first": "erste",
    "second": "zweite",
    "third": "dritte",
    "half": "halb",
    "a quarter": "ein Viertel",
    "a dozen": "ein Dutzend",
    "double": "doppelt",
    "today": "heute",
    "tomorrow": "morgen",
    "yesterday": "gestern",
    "now": "jetzt",
    "later": "sp\xE4ter",
    "morning": "Morgen",
    "afternoon": "Nachmittag",
    "evening": "Abend",
    "night": "Nacht",
    "monday": "Montag",
    "tuesday": "Dienstag",
    "wednesday": "Mittwoch",
    "thursday": "Donnerstag",
    "friday": "Freitag",
    "saturday": "Samstag",
    "sunday": "Sonntag",
    "january": "Januar",
    "february": "Februar",
    "march": "M\xE4rz",
    "april": "April",
    "may": "Mai",
    "june": "Juni",
    "july": "Juli",
    "august": "August",
    "september": "September",
    "october": "Oktober",
    "november": "November",
    "december": "Dezember",
    "what time is it?": "wie sp\xE4t ist es?",
    "at what time?": "um wie viel Uhr?",
    "what day is today?": "welcher Tag ist heute?",
    "when?": "wann?",
    "in the morning": "am Morgen",
    "in the afternoon": "am Nachmittag",
    "at night": "nachts",
    "what": "was",
    "when": "wann",
    "why": "warum",
    "how": "wie",
    "which": "welche",
    "what is this?": "was ist das?",
    "where is...?": "wo ist...?",
    "when does it open?": "wann \xF6ffnet es?",
    "who is that?": "wer ist das?",
    "why?": "warum?",
    "how do i get to...?": "wie komme ich zu...?",
    "how much does it cost?": "wie viel kostet es?",
    "how long?": "wie lange?",
    "how far?": "wie weit?",
    "can you help me?": "kannst du mir helfen?",
    "can i...?": "kann ich...?",
    "is there...?": "gibt es...?",
    "do you have...?": "hast du...?",
    "food": "Essen",
    "water": "Wasser",
    "bread": "Brot",
    "meat": "Fleisch",
    "chicken": "H\xE4hnchen",
    "fish": "Fisch",
    "rice": "Reis",
    "vegetable": "Gem\xFCse",
    "fruit": "Obst",
    "egg": "Ei",
    "cheese": "K\xE4se",
    "milk": "Milch",
    "coffee": "Kaffee",
    "tea": "Tee",
    "beer": "Bier",
    "wine": "Wein",
    "juice": "Saft",
    "salt": "Salz",
    "sugar": "Zucker",
    "hot": "hei\xDF",
    "cold": "kalt",
    "delicious": "lecker",
    "i would like...": "ich h\xE4tte gern...",
    "i'm hungry": "ich habe Hunger",
    "i'm thirsty": "ich habe Durst",
    "the check, please": "die Rechnung, bitte",
    "a table for two": "ein Tisch f\xFCr zwei",
    "menu, please": "die Speisekarte, bitte",
    "cheers!": "prost!",
    "enjoy your meal": "guten Appetit",
    "it's delicious": "es ist lecker",
    "no ice, please": "kein Eis, bitte",
    "to go": "zum Mitnehmen",
    "vegetarian": "vegetarisch",
    "gluten-free": "glutenfrei",
    "spicy": "scharf",
    "without...": "ohne...",
    "more bread, please": "mehr Brot, bitte",
    "water, please": "Wasser, bitte",
    "breakfast": "Fr\xFChst\xFCck",
    "lunch": "Mittagessen",
    "dinner": "Abendessen",
    "here": "hier",
    "there": "dort",
    "left": "links",
    "right": "rechts",
    "straight": "geradeaus",
    "near": "nah",
    "far": "weit",
    "street": "Stra\xDFe",
    "corner": "Ecke",
    "bus": "Bus",
    "taxi": "Taxi",
    "train": "Zug",
    "airport": "Flughafen",
    "station": "Bahnhof",
    "hotel": "Hotel",
    "map": "Karte",
    "where is the bathroom?": "wo ist die Toilette?",
    "turn left": "links abbiegen",
    "turn right": "rechts abbiegen",
    "go straight": "geradeaus gehen",
    "it's near": "es ist nah",
    "it's far": "es ist weit weg",
    "stop here, please": "halten Sie bitte hier",
    "ticket": "Ticket",
    "platform": "Bahnsteig",
    "gate": "Gate",
    "departure": "Abfahrt",
    "arrival": "Ankunft",
    "family": "Familie",
    "mom": "Mama",
    "dad": "Papa",
    "mother": "Mutter",
    "father": "Vater",
    "brother": "Bruder",
    "sister": "Schwester",
    "son": "Sohn",
    "daughter": "Tochter",
    "friend": "Freund",
    "child": "Kind",
    "baby": "Baby",
    "person": "Person",
    "people": "Menschen",
    "man": "Mann",
    "woman": "Frau",
    "teacher": "Lehrer",
    "student": "Sch\xFCler",
    "doctor": "Arzt",
    "work": "Arbeit",
    "school": "Schule",
    "home": "Zuhause",
    "house": "Haus",
    "room": "Zimmer",
    "kitchen": "K\xFCche",
    "bathroom": "Badezimmer",
    "door": "T\xFCr",
    "window": "Fenster",
    "table": "Tisch",
    "chair": "Stuhl",
    "bed": "Bett",
    "book": "Buch",
    "phone": "Telefon",
    "computer": "Computer",
    "car": "Auto",
    "money": "Geld",
    "price": "Preis",
    "cheap": "billig",
    "expensive": "teuer",
    "big": "gro\xDF",
    "small": "klein",
    "good": "gut",
    "bad": "schlecht",
    "new": "neu",
    "old": "alt",
    "beautiful": "sch\xF6n",
    "ugly": "h\xE4sslich",
    "easy": "einfach",
    "difficult": "schwierig",
    "fast": "schnell",
    "slow": "langsam",
    "happy": "gl\xFCcklich",
    "sad": "traurig",
    "tired": "m\xFCde",
    "sick": "krank",
    "busy": "besch\xE4ftigt",
    "ready": "bereit",
    "red": "rot",
    "blue": "blau",
    "green": "gr\xFCn",
    "yellow": "gelb",
    "black": "schwarz",
    "white": "wei\xDF",
    "orange": "orange",
    "purple": "lila",
    "pink": "rosa",
    "brown": "braun",
    "gray": "grau",
    "monday morning": "Montagmorgen",
    "i don't understand": "ich verstehe nicht",
    "please repeat": "bitte wiederholen",
    "speak slowly": "sprich langsam",
    "i need help": "ich brauche Hilfe",
    "call a doctor": "rufen Sie einen Arzt",
    "where is the hospital?": "wo ist das Krankenhaus?",
    "i am lost": "ich habe mich verlaufen",
    "emergency": "Notfall",
    "passport": "Reisepass",
    "reservation": "Reservierung",
    "i have a reservation": "ich habe eine Reservierung",
    "nice": "nett",
    "kind": "freundlich",
    "important": "wichtig",
    "interesting": "interessant",
    "because": "weil",
    "but": "aber",
    "and": "und",
    "or": "oder",
    "with": "mit",
    "without": "ohne",
    "before": "vorher",
    "after": "nachher",
    "always": "immer",
    "never": "nie",
    "sometimes": "manchmal",
    "often": "oft",
    "yesterday's actions": "Handlungen von gestern",
    "future plans": "Zukunftspl\xE4ne",
    "polite expressions": "h\xF6fliche Ausdr\xFCcke",
    "conditional would": "Konditional mit would",
    "break a leg": "viel Gl\xFCck",
    "it's raining cats and dogs": "es regnet in Str\xF6men",
    "piece of cake": "ein Kinderspiel",
    "costs an arm and a leg": "kostet ein Verm\xF6gen",
    "once in a blue moon": "alle Jubeljahre",
    "under the weather": "nicht ganz fit",
    "spill the beans": "das Geheimnis verraten",
    "hit the nail on the head": "den Nagel auf den Kopf treffen",
    "better late than never": "besser sp\xE4t als nie",
    "practice makes perfect": "\xDCbung macht den Meister",
    "rome wasn't built in a day": "Rom wurde nicht an einem Tag erbaut",
    "to be perfectly frank...": "ganz offen gesagt...",
    "between you and me...": "unter uns gesagt...",
    "to whom it may concern": "sehr geehrte Damen und Herren",
    "in accordance with": "in \xDCbereinstimmung mit",
    "the (masculine)": "der (maskulin)",
    "the (feminine)": "die (feminin)"
  };
  var SUPPLEMENTAL_CONCEPT_TRANSLATIONS = {
    "grandfather": "Gro\xDFvater",
    "grandmother": "Gro\xDFmutter",
    "boy": "Junge",
    "girl": "M\xE4dchen",
    "bye": "tsch\xFCss",
    "hi": "hi",
    "okay": "okay",
    "I'm fine": "mir geht es gut",
    "I don't know": "ich wei\xDF nicht",
    "I understand": "ich verstehe",
    "more or less": "mehr oder weniger",
    "of course": "nat\xFCrlich",
    "thanks a lot": "vielen Dank",
    "no problem": "kein Problem",
    "help": "Hilfe",
    "help me please": "hilf mir bitte",
    "with pleasure": "mit Vergn\xFCgen",
    "it's nothing": "keine Ursache",
    "pen": "Stift",
    "pencil": "Bleistift",
    "paper": "Papier",
    "I am...": "ich bin...",
    "I am from...": "ich komme aus...",
    "And you?": "Und du?",
    "this is...": "das ist...",
    "pleased to meet you": "freut mich, dich kennenzulernen",
    "Take me to...": "Bring mich zu...",
    "How much to...?": "Wie viel bis...?",
    "One ticket, please": "Ein Ticket, bitte",
    "What time does it leave?": "Wann f\xE4hrt es ab?",
    "Entrance": "Eingang",
    "Exit": "Ausgang",
    "Buy": "Kaufen",
    "Pay": "Bezahlen",
    "Store": "Gesch\xE4ft",
    "Open": "Offen",
    "Closed": "Geschlossen",
    "Receipt": "Quittung",
    "I'll take it": "Ich nehme es",
    "Do you accept credit cards?": "Akzeptieren Sie Kreditkarten?",
    "Can I pay with...?": "Kann ich mit ... bezahlen?",
    "Is there a discount?": "Gibt es einen Rabatt?",
    "Just looking": "Ich schaue nur",
    "What size?": "Welche Gr\xF6\xDFe?",
    "Can I try it on?": "Kann ich es anprobieren?",
    "Receipt, please": "Die Quittung, bitte",
    "Cash": "Bargeld",
    "Card": "Karte",
    "Key": "Schl\xFCssel",
    "Towel": "Handtuch",
    "Wi-Fi": "WLAN",
    "For how many nights?": "F\xFCr wie viele N\xE4chte?",
    "Can I see the room?": "Kann ich das Zimmer sehen?",
    "What's the Wi-Fi password?": "Wie lautet das WLAN-Passwort?",
    "What time is checkout?": "Wann ist der Check-out?",
    "Do you have a room available?": "Haben Sie ein Zimmer frei?",
    "Is breakfast included?": "Ist das Fr\xFChst\xFCck inbegriffen?",
    "I need more towels": "Ich brauche mehr Handt\xFCcher",
    "Hospital": "Krankenhaus",
    "Police": "Polizei",
    "Pharmacy": "Apotheke",
    "Pain": "Schmerz",
    "I need help!": "Ich brauche Hilfe!",
    "Call the police": "Rufen Sie die Polizei",
    "I'm lost": "Ich habe mich verlaufen",
    "I don't feel well": "Ich f\xFChle mich nicht gut",
    "Where's the hospital?": "Wo ist das Krankenhaus?",
    "I need a doctor": "Ich brauche einen Arzt",
    "It hurts here": "Es tut hier weh",
    "Want": "Wollen",
    "Need": "Brauchen",
    "Have": "Haben",
    "Be": "Sein",
    "Go": "Gehen",
    "Come": "Kommen",
    "See": "Sehen",
    "Speak": "Sprechen",
    "Understand": "Verstehen",
    "Know": "Wissen",
    "Like": "M\xF6gen",
    "Eat": "Essen",
    "Drink": "Trinken",
    "Sleep": "Schlafen",
    "Give": "Geben",
    "Take": "Nehmen",
    "Make": "Machen",
    "Do": "Tun",
    "Can": "K\xF6nnen",
    "Can you speak more slowly?": "K\xF6nnen Sie langsamer sprechen?",
    "Can you repeat that?": "K\xF6nnen Sie das wiederholen?",
    "What does that mean?": "Was bedeutet das?",
    "How do you say...?": "Wie sagt man...?",
    "Do you understand me?": "Verstehen Sie mich?",
    "I speak a little": "Ich spreche ein bisschen",
    "I'm learning": "Ich lerne",
    "Could you write it down?": "K\xF6nnten Sie es aufschreiben?",
    "Can you help me with...?": "K\xF6nnen Sie mir mit ... helfen?",
    "I think so": "Ich glaube schon",
    "I don't think so": "Ich glaube nicht",
    "It doesn't matter": "Es ist egal",
    "Whatever you prefer": "Wie du m\xF6chtest",
    "It depends": "Es kommt darauf an",
    "Let me think": "Lass mich nachdenken",
    "I'm not sure": "Ich bin nicht sicher",
    "Maybe later": "Vielleicht sp\xE4ter",
    "Not now": "Nicht jetzt",
    "I agree": "Ich stimme zu",
    "I disagree": "Ich stimme nicht zu",
    "You're right": "Du hast recht",
    "That's true": "Das stimmt",
    "Really?": "Wirklich?",
    "Are you serious?": "Meinst du das ernst?",
    "I hope so": "Ich hoffe es",
    "Good luck!": "Viel Gl\xFCck!",
    "Take care": "Pass auf dich auf",
    "Exactly": "Genau",
    "Absolutely": "Absolut",
    "Probably": "Wahrscheinlich",
    "Unfortunately": "Leider",
    "Luckily": "Zum Gl\xFCck",
    "Actually": "Eigentlich",
    "Anyway": "Jedenfalls",
    "By the way": "\xDCbrigens",
    "Never mind": "Schon gut",
    "Forget it": "Vergiss es",
    "Husband": "Ehemann",
    "Wife": "Ehefrau",
    "Boyfriend": "Freund",
    "Girlfriend": "Freundin",
    "Uncle": "Onkel",
    "Aunt": "Tante",
    "Cousin": "Cousin/Cousine",
    "Parent": "Elternteil",
    "Single": "ledig",
    "Married": "verheiratet",
    "Divorced": "geschieden",
    "This is my family": "Das ist meine Familie",
    "Do you have siblings?": "Hast du Geschwister?",
    "Are you married?": "Bist du verheiratet?",
    "I'm single": "Ich bin ledig",
    "I have two children": "Ich habe zwei Kinder",
    "My parents live in...": "Meine Eltern wohnen in...",
    "I miss my family": "Ich vermisse meine Familie",
    "Relatives": "Verwandte",
    "Job": "Beruf",
    "Office": "B\xFCro",
    "Boss": "Chef",
    "Colleague": "Kollege/Kollegin",
    "Nurse": "Krankenpfleger/in",
    "Engineer": "Ingenieur/in",
    "Lawyer": "Anwalt/Anw\xE4ltin",
    "Manager": "Manager/in",
    "Employee": "Angestellte/r",
    "Salary": "Gehalt",
    "Meeting": "Besprechung",
    "What do you do?": "Was machst du beruflich?",
    "I work as a...": "Ich arbeite als...",
    "I'm a student": "Ich bin Student/in",
    "I'm unemployed": "Ich bin arbeitslos",
    "I work from home": "Ich arbeite von zu Hause",
    "What time do you finish work?": "Wann hast du Feierabend?",
    "I have a meeting": "Ich habe eine Besprechung",
    "I'm on vacation": "Ich bin im Urlaub",
    "I'm busy": "Ich bin besch\xE4ftigt",
    "I'm retired": "Ich bin in Rente",
    "Music": "Musik",
    "Movie": "Film",
    "Sport": "Sport",
    "Game": "Spiel",
    "Photo": "Foto",
    "Dance": "Tanzen",
    "Swim": "Schwimmen",
    "Run": "Laufen",
    "Walk": "Gehen",
    "Read": "Lesen",
    "Watch": "Anschauen",
    "Listen": "Zuh\xF6ren",
    "Play": "Spielen",
    "Hobby": "Hobby",
    "Free time": "Freizeit",
    "Weekend": "Wochenende",
    "Party": "Party",
    "Fun": "Spa\xDF",
    "What do you like to do?": "Was machst du gern?",
    "In my free time...": "In meiner Freizeit...",
    "On weekends...": "Am Wochenende...",
    "I like to...": "Ich mag es...",
    "I love...": "Ich liebe...",
    "I hate...": "Ich hasse...",
    "I enjoy...": "Ich genie\xDFe...",
    "It's boring": "Es ist langweilig",
    "It's fun": "Es macht Spa\xDF",
    "It's interesting": "Es ist interessant",
    "Do you want to go to...?": "M\xF6chtest du zu ... gehen?",
    "Let's go to...": "Lass uns zu ... gehen",
    "Shall we...?": "Sollen wir...?",
    "Would you like to...?": "M\xF6chtest du...?",
    "Relax": "Entspannen",
    "Tall": "gro\xDF",
    "Short": "klein",
    "Fat": "dick",
    "Thin": "d\xFCnn",
    "Strong": "stark",
    "Weak": "schwach",
    "Young": "jung",
    "Angry": "w\xFCtend",
    "Hungry": "hungrig",
    "Thirsty": "durstig",
    "Nervous": "nerv\xF6s",
    "Excited": "aufgeregt",
    "Bored": "gelangweilt",
    "Interested": "interessiert",
    "Smart": "klug",
    "Stupid": "dumm",
    "Mean": "gemein",
    "Friendly": "freundlich",
    "Funny": "lustig",
    "Serious": "ernst",
    "Handsome": "gutaussehend",
    "Pretty": "h\xFCbsch",
    "Clean": "sauber",
    "Dirty": "schmutzig",
    "Comfortable": "bequem",
    "Uncomfortable": "unbequem",
    "Safe": "sicher",
    "Dangerous": "gef\xE4hrlich",
    "Loud": "laut",
    "Weather": "Wetter",
    "Sun": "Sonne",
    "Rain": "Regen",
    "Snow": "Schnee",
    "Wind": "Wind",
    "Cloud": "Wolke",
    "Warm": "warm",
    "Cool": "k\xFChl",
    "Storm": "Sturm",
    "Temperature": "Temperatur",
    "Degree": "Grad",
    "Season": "Jahreszeit",
    "Spring": "Fr\xFChling",
    "Summer": "Sommer",
    "Fall": "Herbst",
    "Winter": "Winter",
    "Beach": "Strand",
    "Mountain": "Berg",
    "River": "Fluss",
    "Lake": "See",
    "Tree": "Baum",
    "Flower": "Blume",
    "Animal": "Tier",
    "Apartment": "Wohnung",
    "Bedroom": "Schlafzimmer",
    "Living room": "Wohnzimmer",
    "Floor": "Boden",
    "Wall": "Wand",
    "Ceiling": "Decke",
    "Furniture": "M\xF6bel",
    "Sofa": "Sofa",
    "Lamp": "Lampe",
    "TV": "Fernseher",
    "Address": "Adresse",
    "Rent": "Miete",
    "I live in an apartment": "Ich wohne in einer Wohnung",
    "I live alone": "Ich wohne allein",
    "I live with...": "Ich wohne mit...",
    "How many rooms?": "Wie viele Zimmer?",
    "Clothes": "Kleidung",
    "Shirt": "Hemd",
    "Pants": "Hose",
    "Dress": "Kleid",
    "Skirt": "Rock",
    "Jacket": "Jacke",
    "Coat": "Mantel",
    "Shoes": "Schuhe",
    "Socks": "Socken",
    "Hat": "Hut",
    "Glasses": "Brille",
    "Bag": "Tasche",
    "Size": "Gr\xF6\xDFe",
    "Trip": "Reise",
    "Journey": "Reise",
    "Vacation": "Urlaub",
    "Tourist": "Tourist/in",
    "Guide": "Reisef\xFChrer/in",
    "Visa": "Visum",
    "Flight": "Flug",
    "Boarding pass": "Bordkarte",
    "Luggage": "Gep\xE4ck",
    "Suitcase": "Koffer",
    "Backpack": "Rucksack",
    "Customs": "Zoll",
    "Immigration": "Einreise",
    "Destination": "Reiseziel",
    "Itinerary": "Reiseplan",
    "Excursion": "Ausflug",
    "I'm here on vacation": "Ich bin hier im Urlaub",
    "I'm here for business": "Ich bin gesch\xE4ftlich hier",
    "How long are you staying?": "Wie lange bleibst du?",
    "I'm staying for... days": "Ich bleibe ... Tage",
    "Where are you staying?": "Wo wohnst du?",
    "I've lost my passport": "Ich habe meinen Pass verloren",
    "I've missed my flight": "Ich habe meinen Flug verpasst",
    "When does boarding start?": "Wann beginnt das Boarding?",
    "What gate?": "Welches Gate?",
    "Is this seat taken?": "Ist dieser Platz besetzt?",
    "Can I switch seats?": "Kann ich den Platz wechseln?",
    "I feel airsick": "Mir ist im Flugzeug \xFCbel",
    "Could you store this for me?": "K\xF6nnten Sie das f\xFCr mich verstauen?",
    "Is there a layover?": "Gibt es einen Zwischenstopp?",
    "Where do I pick up my luggage?": "Wo hole ich mein Gep\xE4ck ab?",
    "My luggage is missing": "Mein Gep\xE4ck fehlt",
    "I have nothing to declare": "Ich habe nichts zu verzollen",
    "This is for personal use": "Das ist f\xFCr den pers\xF6nlichen Gebrauch",
    "I'm just passing through": "Ich bin nur auf der Durchreise",
    "How do I get to the city center?": "Wie komme ich ins Stadtzentrum?",
    "Delay": "Versp\xE4tung",
    "Cancel": "Stornieren",
    "Confirm": "Best\xE4tigen",
    "Invite": "Einladen",
    "Plan": "Planen",
    "Schedule": "Zeitplan",
    "Appointment": "Termin",
    "Date": "Verabredung",
    "Event": "Veranstaltung",
    "Celebration": "Feier",
    "Gathering": "Treffen",
    "What are you doing tonight?": "Was machst du heute Abend?",
    "Do you have plans?": "Hast du Pl\xE4ne?",
    "Would you like to join us?": "M\xF6chtest du mitkommen?",
    "We're going to...": "Wir gehen zu...",
    "Want to come along?": "Willst du mitkommen?",
    "What time works for you?": "Welche Uhrzeit passt dir?",
    "Where should we meet?": "Wo sollen wir uns treffen?",
    "Let's meet at...": "Treffen wir uns um/bei...",
    "I'll pick you up": "Ich hole dich ab",
    "I'll be there at...": "Ich bin um ... da",
    "Sorry, I can't make it": "Tut mir leid, ich schaffe es nicht",
    "I'm busy that day": "An dem Tag bin ich besch\xE4ftigt",
    "Can we reschedule?": "K\xF6nnen wir verschieben?",
    "I'm looking forward to it": "Ich freue mich darauf",
    "I'm running late": "Ich bin sp\xE4t dran",
    "I'm on my way": "Ich bin unterwegs",
    "Thanks for inviting me": "Danke f\xFCr die Einladung",
    "Let's do this again": "Lass uns das wieder machen",
    "Keep in touch": "Bleib in Kontakt",
    "Waiter": "Kellner/in",
    "Chef": "Koch/K\xF6chin",
    "Ingredient": "Zutat",
    "Dish": "Gericht",
    "Appetizer": "Vorspeise",
    "Main course": "Hauptgericht",
    "Dessert": "Dessert",
    "Portion": "Portion",
    "Recommendation": "Empfehlung",
    "Allergy": "Allergie",
    "Vegan": "vegan",
    "I have a reservation under...": "Ich habe eine Reservierung auf den Namen...",
    "A table for four, please": "Einen Tisch f\xFCr vier, bitte",
    "Do you have a table available?": "Haben Sie einen Tisch frei?",
    "How long is the wait?": "Wie lange ist die Wartezeit?",
    "We'd like to sit outside": "Wir m\xF6chten drau\xDFen sitzen",
    "Can we see the menu?": "K\xF6nnen wir die Speisekarte sehen?",
    "What do you recommend?": "Was empfehlen Sie?",
    "What's the specialty?": "Was ist die Spezialit\xE4t?",
    "I'm allergic to...": "Ich bin allergisch gegen...",
    "I can't eat...": "Ich kann ... nicht essen",
    "Is this dish spicy?": "Ist dieses Gericht scharf?",
    "Can you make it without...?": "K\xF6nnen Sie es ohne ... machen?",
    "This isn't what I ordered": "Das ist nicht, was ich bestellt habe",
    "This is cold": "Das ist kalt",
    "Can we have separate checks?": "K\xF6nnen wir getrennte Rechnungen bekommen?",
    "Let's split it": "Lass es uns teilen",
    "Keep the change": "Stimmt so",
    "Feel": "F\xFChlen",
    "Emotion": "Gef\xFChl",
    "Frustrated": "frustriert",
    "Stressed": "gestresst",
    "Worried": "besorgt",
    "Anxious": "\xE4ngstlich",
    "Calm": "ruhig",
    "Relaxed": "entspannt",
    "Surprised": "\xFCberrascht",
    "Confused": "verwirrt",
    "Disappointed": "entt\xE4uscht",
    "Grateful": "dankbar",
    "Proud": "stolz",
    "Ashamed": "besch\xE4mt",
    "Jealous": "eifers\xFCchtig",
    "Lonely": "einsam",
    "Homesick": "heimwehkrank",
    "I'm feeling...": "Ich f\xFChle mich...",
    "That makes me angry": "Das macht mich w\xFCtend",
    "I'm grateful for...": "Ich bin dankbar f\xFCr...",
    "Don't worry": "Mach dir keine Sorgen",
    "Problem": "Problem",
    "Solution": "L\xF6sung",
    "Issue": "Thema",
    "Trouble": "Schwierigkeit",
    "Difficulty": "Schwierigkeit",
    "Mistake": "Fehler",
    "Error": "Fehler",
    "Fix": "Reparieren",
    "Repair": "Reparieren",
    "Replace": "Ersetzen",
    "Complaint": "Beschwerde",
    "Refund": "R\xFCckerstattung",
    "I have a problem": "Ich habe ein Problem",
    "There's a problem with...": "Es gibt ein Problem mit...",
    "Something's wrong with...": "Mit ... stimmt etwas nicht",
    "It doesn't work": "Es funktioniert nicht",
    "It's broken": "Es ist kaputt",
    "Can you fix it?": "K\xF6nnen Sie es reparieren?",
    "Can you replace it?": "K\xF6nnen Sie es ersetzen?",
    "I'd like a refund": "Ich m\xF6chte eine R\xFCckerstattung",
    "I'd like to exchange this": "Ich m\xF6chte das umtauschen",
    "This is defective": "Das ist defekt",
    "I want to file a complaint": "Ich m\xF6chte eine Beschwerde einreichen",
    "Can I speak to the manager?": "Kann ich mit dem Manager sprechen?",
    "This is unacceptable": "Das ist inakzeptabel",
    "You made a mistake": "Sie haben einen Fehler gemacht",
    "Let me explain": "Lassen Sie mich erkl\xE4ren",
    "What are my options?": "Welche Optionen habe ich?",
    "I need this urgently": "Ich brauche das dringend",
    "How long will it take?": "Wie lange wird es dauern?",
    "Experience": "Erfahrung",
    "Memory": "Erinnerung",
    "Moment": "Moment",
    "Story": "Geschichte",
    "I've been to...": "Ich war schon in...",
    "I've never been to...": "Ich war noch nie in...",
    "I've tried...": "Ich habe ... probiert",
    "I've never tried...": "Ich habe ... noch nie probiert",
    "It was amazing": "Es war gro\xDFartig",
    "It was terrible": "Es war schrecklich",
    "It was worth it": "Es hat sich gelohnt",
    "I regret...": "Ich bereue...",
    "The best part was...": "Das Beste war...",
    "The worst part was...": "Das Schlimmste war...",
    "I'll never forget...": "Ich werde ... nie vergessen",
    "It reminded me of...": "Es erinnerte mich an...",
    "It was different from...": "Es war anders als...",
    "It was similar to...": "Es war \xE4hnlich wie...",
    "Looking back...": "R\xFCckblickend...",
    "Next time I'll...": "N\xE4chstes Mal werde ich...",
    "Symptom": "Symptom",
    "Fever": "Fieber",
    "Headache": "Kopfschmerzen",
    "Stomachache": "Bauchschmerzen",
    "Cough": "Husten",
    "Flu": "Grippe",
    "Injury": "Verletzung",
    "Wound": "Wunde",
    "Medicine": "Medizin",
    "Prescription": "Rezept",
    "Insurance": "Versicherung",
    "I'm sick": "Ich bin krank",
    "I have a fever": "Ich habe Fieber",
    "My head hurts": "Mein Kopf tut weh",
    "I'm dizzy": "Mir ist schwindlig",
    "I'm nauseous": "Mir ist \xFCbel",
    "I hurt my...": "Ich habe mir ... verletzt",
    "I need medicine for...": "Ich brauche Medizin gegen...",
    "Do I need a prescription?": "Brauche ich ein Rezept?",
    "I need to see a doctor": "Ich muss einen Arzt sehen",
    "Can I make an appointment?": "Kann ich einen Termin vereinbaren?",
    "It costs an arm and a leg": "Es kostet ein Verm\xF6gen",
    "Beat around the bush": "Um den hei\xDFen Brei herumreden",
    "Get the ball rolling": "Den Stein ins Rollen bringen",
    "When pigs fly": "Wenn Schweine fliegen",
    "Actions speak louder than words": "Taten sagen mehr als Worte",
    "Kill two birds with one stone": "Zwei Fliegen mit einer Klappe schlagen",
    "The early bird catches the worm": "Der fr\xFChe Vogel f\xE4ngt den Wurm",
    "Don't count your chickens before they hatch": "Freu dich nicht zu fr\xFCh",
    "Every cloud has a silver lining": "Jede Wolke hat einen Silberstreif",
    "You can't have your cake and eat it too": "Man kann nicht alles gleichzeitig haben",
    "The ball is in your court": "Der Ball liegt bei dir",
    "Bite off more than you can chew": "Sich mehr vornehmen, als man schaffen kann",
    "Burn the midnight oil": "Bis sp\xE4t in die Nacht arbeiten",
    "Call it a day": "Feierabend machen",
    "Cut to the chase": "Komm zum Punkt",
    "Let the cat out of the bag": "Die Katze aus dem Sack lassen",
    "Break the ice": "Das Eis brechen",
    "Cost a fortune": "Ein Verm\xF6gen kosten",
    "In a nutshell": "Kurz gesagt",
    "Get cold feet": "Kalte F\xFC\xDFe bekommen",
    "On the same page": "Auf derselben Wellenl\xE4nge",
    "Back to square one": "Zur\xFCck auf Anfang",
    "Deadline": "Frist",
    "Project": "Projekt",
    "Client": "Kunde/Kundin",
    "Contract": "Vertrag",
    "Agreement": "Vereinbarung",
    "Negotiate": "Verhandeln",
    "Strategy": "Strategie",
    "Goal": "Ziel",
    "Objective": "Zielsetzung",
    "Achievement": "Leistung",
    "Let's schedule a meeting": "Lass uns ein Meeting planen",
    "I'll send you the agenda": "Ich schicke dir die Tagesordnung",
    "Let's get down to business": "Kommen wir zur Sache",
    "We need to meet the deadline": "Wir m\xFCssen die Frist einhalten",
    "The project is behind schedule": "Das Projekt liegt hinter dem Zeitplan",
    "We're on track": "Wir liegen im Plan",
    "What's the status?": "Wie ist der Stand?",
    "Any updates?": "Gibt es Neuigkeiten?",
    "I'll keep you posted": "Ich halte dich auf dem Laufenden",
    "Let me get back to you on that": "Ich komme darauf zur\xFCck",
    "I'll follow up with you": "Ich melde mich dazu wieder",
    "Could you send that in writing?": "K\xF6nnten Sie das schriftlich schicken?",
    "As per our conversation": "Wie besprochen",
    "Moving forward...": "K\xFCnftig...",
    "Let's touch base": "Lass uns kurz abstimmen",
    "Let's circle back to this": "Lass uns darauf zur\xFCckkommen",
    "I'll loop you in": "Ich beziehe dich mit ein",
    "Keep me in the loop": "Halte mich auf dem Laufenden",
    "Performance": "Leistung",
    "Budget": "Budget",
    "I strongly believe that...": "Ich bin fest davon \xFCberzeugt, dass...",
    "There's no doubt that...": "Es besteht kein Zweifel daran, dass...",
    "It's obvious that": "Es ist offensichtlich, dass",
    "Clearly...": "Eindeutig...",
    "It's obvious that...": "Es ist offensichtlich, dass...",
    "Obviously...": "Offensichtlich...",
    "Without a doubt...": "Ohne Zweifel...",
    "On the other hand...": "Andererseits...",
    "However...": "Allerdings...",
    "Nevertheless...": "Nichtsdestotrotz...",
    "Despite that...": "Trotzdem...",
    "Even so...": "Selbst dann...",
    "That being said...": "Abgesehen davon...",
    "That may be true, but...": "Das mag stimmen, aber...",
    "I see your point, but...": "Ich verstehe deinen Punkt, aber...",
    "I understand what you mean, but...": "Ich verstehe, was du meinst, aber...",
    "With all due respect...": "Bei allem Respekt...",
    "I beg to differ": "Da bin ich anderer Meinung",
    "I completely disagree": "Ich stimme \xFCberhaupt nicht zu",
    "That's not necessarily true": "Das ist nicht unbedingt wahr",
    "According to...": "Laut...",
    "Studies show that...": "Studien zeigen, dass...",
    "Evidence suggests...": "Die Belege deuten darauf hin...",
    "In fact...": "Tats\xE4chlich...",
    "To be honest...": "Ehrlich gesagt...",
    "Actually...": "Tats\xE4chlich...",
    "Freedom": "Freiheit",
    "Justice": "Gerechtigkeit",
    "Equality": "Gleichheit",
    "Democracy": "Demokratie",
    "Rights": "Rechte",
    "Responsibility": "Verantwortung",
    "Ethics": "Ethik",
    "Morality": "Moral",
    "Truth": "Wahrheit",
    "Beauty": "Sch\xF6nheit",
    "Love": "Liebe",
    "Hate": "Hass",
    "Faith": "Glaube",
    "Hope": "Hoffnung",
    "Dream": "Traum",
    "Reality": "Realit\xE4t",
    "Imagination": "Vorstellungskraft",
    "Creativity": "Kreativit\xE4t",
    "Intelligence": "Intelligenz",
    "Wisdom": "Weisheit",
    "Environment": "Umwelt",
    "Climate change": "Klimawandel",
    "Pollution": "Verschmutzung",
    "Poverty": "Armut",
    "Inequality": "Ungleichheit",
    "Education": "Bildung",
    "Healthcare": "Gesundheitsversorgung",
    "Politics": "Politik",
    "Government": "Regierung",
    "Economy": "Wirtschaft",
    "Unemployment": "Arbeitslosigkeit",
    "Crime": "Kriminalit\xE4t",
    "Violence": "Gewalt",
    "Peace": "Frieden",
    "War": "Krieg",
    "Discrimination": "Diskriminierung",
    "Racism": "Rassismus",
    "Feminism": "Feminismus",
    "Activism": "Aktivismus",
    "Art": "Kunst",
    "Culture": "Kultur",
    "Museum": "Museum",
    "Gallery": "Galerie",
    "Exhibition": "Ausstellung",
    "Have you seen...?": "Hast du ... gesehen?",
    "Have you read...?": "Hast du ... gelesen?",
    "I highly recommend...": "Ich empfehle ... sehr",
    "It's overrated": "Es ist \xFCberbewertet",
    "It's underrated": "Es ist unterbewertet",
    "It's a must-see": "Das muss man gesehen haben",
    "What did you think of...?": "Was hast du von ... gehalten?",
    "I was blown away": "Ich war \xFCberw\xE4ltigt",
    "It was thought-provoking": "Es war zum Nachdenken anregend",
    "It really makes you think": "Es bringt einen wirklich zum Nachdenken",
    "I'm not entirely sure": "Ich bin mir nicht ganz sicher",
    "I could be wrong, but...": "Ich k\xF6nnte mich irren, aber...",
    "If I had to guess...": "Wenn ich raten m\xFCsste...",
    "It's hard to say": "Das ist schwer zu sagen",
    "It's difficult to tell": "Das l\xE4sst sich schwer sagen",
    "It depends on...": "Es h\xE4ngt von ... ab",
    "That remains to be seen": "Das bleibt abzuwarten",
    "Only time will tell": "Das wird die Zeit zeigen",
    "There's a good chance that...": "Es besteht eine gute Chance, dass...",
    "It's unlikely that...": "Es ist unwahrscheinlich, dass...",
    "Comprehend": "Begreifen",
    "Perceive": "Wahrnehmen",
    "Articulate": "Artikulieren",
    "Contemplate": "Nachdenken",
    "Acquire": "Erwerben",
    "Facilitate": "Erleichtern",
    "Demonstrate": "Demonstrieren",
    "Implement": "Umsetzen",
    "Significant": "bedeutend",
    "Substantial": "erheblich",
    "Meticulous": "akribisch",
    "Profound": "tiefgr\xFCndig",
    "Eloquent": "eloquent",
    "Pragmatic": "pragmatisch",
    "Innovative": "innovativ",
    "Resilient": "widerstandsf\xE4hig",
    "Ambiguous": "mehrdeutig",
    "Arbitrary": "willk\xFCrlich",
    "Inherent": "innewohnend",
    "Reluctant": "widerwillig",
    "To put it another way...": "Anders ausgedr\xFCckt...",
    "In other words...": "Mit anderen Worten...",
    "What I'm trying to say is...": "Was ich sagen m\xF6chte, ist...",
    "The point I'm making is...": "Der Punkt, den ich mache, ist...",
    "To clarify...": "Zur Klarstellung...",
    "To elaborate...": "Um das n\xE4her auszuf\xFChren...",
    "To expand on that...": "Um darauf aufzubauen...",
    "Building on that idea...": "Auf dieser Idee aufbauend...",
    "Taking that further...": "Wenn man das weiterdenkt...",
    "That raises an interesting question...": "Das wirft eine interessante Frage auf...",
    "According to recent research...": "Laut aktueller Forschung...",
    "Studies have shown that...": "Studien haben gezeigt, dass...",
    "It has been demonstrated that...": "Es wurde gezeigt, dass...",
    "It is widely acknowledged that...": "Es ist weithin anerkannt, dass...",
    "Scholars argue that...": "Forschende argumentieren, dass...",
    "The consensus is that...": "Der Konsens ist, dass...",
    "There is considerable debate about...": "Es gibt erhebliche Debatten \xFCber...",
    "This raises the question of...": "Das wirft die Frage auf...",
    "It is worth noting that...": "Es ist erw\xE4hnenswert, dass...",
    "It should be emphasized that...": "Es sollte betont werden, dass...",
    "A key factor is...": "Ein Schl\xFCsselfaktor ist...",
    "A significant aspect is...": "Ein wesentlicher Aspekt ist...",
    "To a large extent...": "In hohem Ma\xDFe...",
    "To some degree...": "Bis zu einem gewissen Grad...",
    "In this context...": "In diesem Kontext...",
    "In light of...": "Angesichts...",
    "With regard to...": "In Bezug auf...",
    "Concerning...": "Bez\xFCglich...",
    "As far as X is concerned...": "Was X betrifft...",
    "From a theoretical perspective...": "Aus theoretischer Perspektive...",
    "From a practical standpoint...": "Aus praktischer Sicht...",
    "In practical terms...": "Praktisch gesprochen...",
    "In theory...": "Theoretisch...",
    "In practice...": "In der Praxis...",
    "Wouldn't you agree that...?": "W\xFCrdest du nicht zustimmen, dass...?",
    "Surely you can see that...": "Du siehst doch sicher, dass...",
    "It goes without saying that...": "Es versteht sich von selbst, dass...",
    "There's no denying that...": "Es l\xE4sst sich nicht leugnen, dass...",
    "One cannot help but notice...": "Man kann nicht umhin zu bemerken...",
    "It stands to reason that...": "Es liegt auf der Hand, dass...",
    "Logic dictates that...": "Die Logik gebietet, dass...",
    "By the same token...": "Aus demselben Grund...",
    "Along the same lines...": "In \xE4hnlicher Weise...",
    "In the same vein...": "Im gleichen Sinne...",
    "Conversely...": "Umgekehrt...",
    "By contrast...": "Im Gegensatz dazu...",
    "In contrast to...": "Im Gegensatz zu...",
    "Whereas...": "W\xE4hrend...",
    "While it's true that...": "Auch wenn es stimmt, dass...",
    "Granted...": "Zugegeben...",
    "Admittedly...": "Zugegebenerma\xDFen...",
    "Be that as it may...": "Wie dem auch sei...",
    "Nonetheless...": "Dennoch...",
    "Notwithstanding...": "Ungeachtet dessen...",
    "Moreover...": "Dar\xFCber hinaus...",
    "Furthermore...": "Au\xDFerdem...",
    "In addition to...": "Zus\xE4tzlich zu...",
    "Not only... but also...": "Nicht nur... sondern auch...",
    "Consequently...": "Folglich...",
    "As a result...": "Infolgedessen...",
    "Therefore...": "Daher...",
    "Thus...": "Somit...",
    "Hence...": "Deshalb...",
    "Accordingly...": "Dementsprechend...",
    "Subsequently...": "Anschlie\xDFend...",
    "In the wake of...": "Im Zuge von...",
    "In lieu of...": "Anstelle von...",
    "Vis-\xE0-vis...": "Im Hinblick auf...",
    "Whereby...": "Wodurch...",
    "Strictly speaking...": "Streng genommen...",
    "Technically speaking...": "Technisch gesehen...",
    "Loosely speaking...": "Locker gesagt...",
    "So to speak...": "Sozusagen...",
    "For lack of a better word...": "Mangels eines besseren Wortes...",
    "If you will...": "Wenn man so will...",
    "As it were...": "Gewisserma\xDFen...",
    "In a manner of speaking...": "In gewisser Weise...",
    "To coin a phrase...": "Um eine Formulierung zu pr\xE4gen...",
    "If I may say so...": "Wenn ich das sagen darf...",
    "Ubiquitous": "allgegenw\xE4rtig",
    "Quintessential": "musterg\xFCltig",
    "Esoteric": "esoterisch",
    "Ephemeral": "verg\xE4nglich",
    "Serendipity": "gl\xFCcklicher Zufall",
    "Paradigm": "Paradigma",
    "Juxtaposition": "Gegen\xFCberstellung",
    "Cognizant": "sich bewusst",
    "Conundrum": "R\xE4tsel",
    "Intrinsic": "inh\xE4rent",
    "Ambivalent": "ambivalent",
    "Scrutinize": "genau pr\xFCfen",
    "Alleviate": "lindern",
    "Perpetuate": "fortbestehen lassen",
    "Superfluous": "\xFCberfl\xFCssig",
    "Delineate": "abgrenzen",
    "Exacerbate": "versch\xE4rfen",
    "Dichotomy": "Dichotomie",
    "Epitome": "Inbegriff",
    "Proliferate": "sich ausbreiten",
    "Where there's smoke, there's fire": "Wo Rauch ist, ist auch Feuer",
    "The grass is always greener on the other side": "Das Gras ist auf der anderen Seite immer gr\xFCner",
    "Don't put all your eggs in one basket": "Setze nicht alles auf eine Karte",
    "A picture is worth a thousand words": "Ein Bild sagt mehr als tausend Worte",
    "The pen is mightier than the sword": "Die Feder ist m\xE4chtiger als das Schwert",
    "You can't judge a book by its cover": "Man soll ein Buch nicht nach dem Einband beurteilen",
    "Two heads are better than one": "Vier Augen sehen mehr als zwei",
    "Time heals all wounds": "Die Zeit heilt alle Wunden",
    "Honesty is the best policy": "Ehrlichkeit w\xE4hrt am l\xE4ngsten",
    "Good things come to those who wait": "Gut Ding will Weile haben",
    "All's fair in love and war": "In der Liebe und im Krieg ist alles erlaubt",
    "The best of both worlds": "Das Beste aus beiden Welten",
    "Beauty is in the eye of the beholder": "Sch\xF6nheit liegt im Auge des Betrachters",
    "If you don't mind my saying...": "Wenn ich das sagen darf...",
    "I couldn't help but notice...": "Mir ist aufgefallen...",
    "Forgive me for saying so...": "Verzeih mir, wenn ich das sage...",
    "Without wishing to offend...": "Ohne dich beleidigen zu wollen...",
    "I hope you won't take this the wrong way...": "Ich hoffe, du verstehst das nicht falsch...",
    "Not to put too fine a point on it...": "Um es klar zu sagen...",
    "Off the record...": "Inoffiziell...",
    "Strictly confidential...": "Streng vertraulich...",
    "Pursuant to our discussion": "Gem\xE4\xDF unserer Besprechung",
    "Notwithstanding the foregoing": "Ungeachtet des Vorstehenden",
    "Herein lies the problem": "Hier liegt das Problem"
  };
  Object.assign(
    CONCEPT_TRANSLATIONS,
    Object.fromEntries(
      Object.entries(SUPPLEMENTAL_CONCEPT_TRANSLATIONS).map(([key, value]) => [
        normalizeKey2(key),
        value
      ])
    )
  );

  // ../nosabos/nosabos/src/data/flashcards/common.js
  var CEFR_LEVEL_COUNTS = {
    "Pre-A1": 100,
    A1: 300,
    A2: 250,
    B1: 200,
    B2: 150,
    C1: 100,
    C2: 50
  };
  var TOTAL_FLASHCARDS = Object.values(CEFR_LEVEL_COUNTS).reduce((a, b) => a + b, 0);

  // ../nosabos/nosabos/src/utils/cefrProgress.js
  var LESSON_COUNTS = {
    "Pre-A1": 86,
    A1: 98,
    A2: 126,
    B1: 105,
    B2: 84,
    C1: 70,
    C2: 56
  };
  function getLessonLevelFromId(lessonId = "") {
    const id = String(lessonId || "").toLowerCase();
    if (!id) return null;
    if (id.includes("lesson-tutorial") || id.includes("unit-tutorial-pre-a1")) {
      return "Pre-A1";
    }
    if (/(?:lesson|unit)-pre-a1(?:-|$)/.test(id)) {
      return "Pre-A1";
    }
    if (/(?:lesson|unit)-a1-(?:1|3|4)(?:-|$)/.test(id)) {
      return "Pre-A1";
    }
    const match = id.match(/(?:lesson|unit)-(a1|a2|b1|b2|c1|c2)(?:-|$)/i);
    return match ? match[1].toUpperCase() : null;
  }
  function calculateLessonCompletion(userProgress, cefrLevel, targetLang = "es") {
    if (!userProgress || !cefrLevel) return 0;
    const lessons = userProgress.languageLessons?.[targetLang] || userProgress.lessons || {};
    const totalLessonsInLevel = LESSON_COUNTS[cefrLevel] || 0;
    if (totalLessonsInLevel === 0) return 0;
    const summaryKey = String(cefrLevel).toLowerCase().replace(/-/g, "_");
    const summaryCompleted = Number(
      userProgress.courseSummary?.skillTree?.levels?.[summaryKey]?.completed
    );
    const completedCount = Number.isFinite(summaryCompleted) ? Math.max(0, summaryCompleted) : Object.keys(lessons).filter((lessonId) => {
      const isInLevel = getLessonLevelFromId(lessonId) === cefrLevel;
      const isCompleted = lessons[lessonId]?.status === "completed";
      return isInLevel && isCompleted;
    }).length;
    return Number((completedCount / totalLessonsInLevel * 100).toFixed(2));
  }
  function calculateFlashcardCompletion(userProgress, cefrLevel, targetLang = "es") {
    if (!userProgress || !cefrLevel) return 0;
    const flashcards = userProgress.languageFlashcards?.[targetLang] || userProgress.flashcards || {};
    const totalFlashcardsInLevel = CEFR_LEVEL_COUNTS[cefrLevel] || 0;
    if (totalFlashcardsInLevel === 0) return 0;
    const summaryKey = String(cefrLevel).toLowerCase().replace(/-/g, "_");
    const summaryCompleted = Number(
      userProgress.courseSummary?.flashcards?.levels?.[summaryKey]?.completed
    );
    const completedCount = Number.isFinite(summaryCompleted) ? Math.max(0, summaryCompleted) : Object.keys(flashcards).filter((cardId) => {
      const isInLevel = cardId.startsWith(`${cefrLevel.toLowerCase()}-`);
      const isCompleted = flashcards[cardId]?.completed === true;
      return isInLevel && isCompleted;
    }).length;
    return Number((completedCount / totalFlashcardsInLevel * 100).toFixed(2));
  }

  // ../nosabos/nosabos/src/utils/performanceEloModel.js
  var ELO_LEVELS = ["Pre-A1", "A1", "A2", "B1", "B2", "C1", "C2"];
  var SCORE_LEVEL_BANDS = Object.freeze({
    "Pre-A1": [0, 14],
    A1: [15, 28],
    A2: [29, 42],
    B1: [43, 56],
    B2: [57, 70],
    C1: [71, 84],
    C2: [85, 100]
  });
  var SCORE_LEVEL_DEFAULTS = Object.freeze({
    "Pre-A1": 1,
    A1: 18,
    A2: 32,
    B1: 46,
    B2: 60,
    C1: 74,
    C2: 89
  });
  var LEGACY_SCORE_POINTS = [[600, 1], [800, 1], [1e3, 125], [1100, 175], [1200, 225], [1400, 325], [1500, 375], [1600, 425], [1700, 475], [1800, 525], [1900, 575], [2e3, 625], [2200, 700]];
  var SCORE_SCALE_VERSION = 4;
  var ELO_SUPPORT_WEIGHTS = Object.freeze({
    modeled: 0.55,
    prompted: 0.7,
    "lightly supported": 0.85,
    independent: 1,
    transferred: 1
  });
  var MIN_SCORE = 0;
  var MAX_SCORE = 100;
  var MIN_RATING = 800;
  var MAX_RATING = 2200;
  var ELO_PER_SCORE = (MAX_RATING - MIN_RATING) / MAX_SCORE;
  function scoreToElo(value) {
    const score = Number(value);
    const bounded = Math.max(MIN_SCORE, Math.min(MAX_SCORE, Number.isFinite(score) ? score : MIN_SCORE));
    if (bounded === MIN_SCORE) return MIN_RATING;
    if (bounded === MAX_SCORE) return MAX_RATING;
    return MIN_RATING + (bounded + 0.5) * ELO_PER_SCORE;
  }
  function eloToScore(value) {
    const rating = Number(value);
    if (!Number.isFinite(rating)) return MIN_SCORE;
    return Math.max(MIN_SCORE, Math.min(MAX_SCORE, Math.floor((rating - MIN_RATING) / ELO_PER_SCORE + 1e-8)));
  }
  function migrateScoreV2(value) {
    const rating = Number(value);
    if (!Number.isFinite(rating)) return null;
    const oldScore = Math.max(1, Math.min(700, rating));
    const levelIndex = Math.min(6, Math.floor((oldScore - 1) / 100));
    const [floor, ceiling] = SCORE_LEVEL_BANDS[ELO_LEVELS[levelIndex]];
    const oldFloor = levelIndex * 100 + 1;
    const migratedFloor = levelIndex === 0 ? 1 : floor;
    return migratedFloor + Math.round((oldScore - oldFloor) / 99 * (ceiling - migratedFloor));
  }
  function migrateLegacyEloRating(value) {
    const rating = Number(value);
    if (!Number.isFinite(rating)) return null;
    if (rating <= LEGACY_SCORE_POINTS[0][0]) return 1;
    for (let index = 1; index < LEGACY_SCORE_POINTS.length; index += 1) {
      const [upperLegacy, upperScore] = LEGACY_SCORE_POINTS[index];
      if (rating <= upperLegacy) {
        const [lowerLegacy, lowerScore] = LEGACY_SCORE_POINTS[index - 1];
        const oldScore = lowerScore + (rating - lowerLegacy) / (upperLegacy - lowerLegacy) * (upperScore - lowerScore);
        return migrateScoreV2(oldScore);
      }
    }
    return MAX_SCORE;
  }
  function storedRating(bucket) {
    if (bucket?.elo?.rating == null) return null;
    const rating = Number(bucket?.elo?.rating);
    if (!Number.isFinite(rating)) return null;
    if (bucket.elo.initializedFrom === "self_report" && !bucket.selfAssessment?.selectedIds?.length && Number(bucket.elo.totalGraded || 0) === 0 && (rating === 1 || rating === 800)) return MIN_RATING;
    if (bucket.elo.scaleVersion === SCORE_SCALE_VERSION)
      return Math.max(MIN_RATING, Math.min(MAX_RATING, rating));
    if (bucket.elo.scaleVersion === 3) return scoreToElo(rating);
    return scoreToElo(bucket.elo.scaleVersion === 2 ? migrateScoreV2(rating) : migrateLegacyEloRating(rating));
  }
  function normalizeEloLevel(value, fallback = "A1") {
    const raw = String(value || "").trim().toUpperCase().replace(/[\s_]+/g, "-");
    if (raw === "PRE-A1" || raw === "PREA1" || raw === "A0") return "Pre-A1";
    if (ELO_LEVELS.includes(raw)) return raw;
    return fallback;
  }
  function initialEloRating(level = "A1") {
    return SCORE_LEVEL_DEFAULTS[normalizeEloLevel(level)] || SCORE_LEVEL_DEFAULTS.A1;
  }
  var higherLevel = (left, right) => ELO_LEVELS[Math.max(
    ELO_LEVELS.indexOf(normalizeEloLevel(left, "Pre-A1")),
    ELO_LEVELS.indexOf(normalizeEloLevel(right, "Pre-A1"))
  )];
  function curriculumLevelsForUser(user, targetLang) {
    const lang = String(targetLang || "es").toLowerCase();
    const placed = user?.proficiencyPlacements?.[lang];
    const unlockedThrough = (completion) => {
      let level = "Pre-A1";
      for (let index = 0; index < ELO_LEVELS.length - 1; index += 1) {
        if (completion(user?.progress, ELO_LEVELS[index], lang) < 100) break;
        level = ELO_LEVELS[index + 1];
      }
      return higherLevel(level, placed);
    };
    const skillTree = unlockedThrough(calculateLessonCompletion);
    const flashcards = unlockedThrough(calculateFlashcardCompletion);
    const tutor = higherLevel(user?.progress?.tutorUnlockedLevels?.[lang], placed);
    const overall = [
      skillTree,
      flashcards,
      tutor,
      user?.progress?.targetLang === lang ? user?.progress?.level : null
    ].reduce(higherLevel, "Pre-A1");
    return { skillTree, flashcards, tutor, overall };
  }
  function initialEloLevelForUser(user, targetLang) {
    return curriculumLevelsForUser(user, targetLang).overall;
  }
  function internalEloForUser(user, targetLang) {
    const lang = String(targetLang || "es").toLowerCase();
    const stored = storedRating(user?.learningIntelligence?.[lang]);
    if (stored !== null) return stored;
    const hasPlacement = Boolean(user?.proficiencyPlacements?.[lang] || user?.progress?.targetLang === lang && user?.proficiencyPlacement);
    const noPractice = Number(user?.xp || 0) === 0 && Number(user?.progress?.xp || 0) === 0 && Number(user?.streak || 0) === 0;
    if (user?.onboarding?.completed === true && !hasPlacement && noPractice)
      return MIN_RATING;
    return scoreToElo(initialEloRating(initialEloLevelForUser(user, lang)));
  }
  function practiceLevelForElo(rating) {
    const score = Number.isFinite(Number(rating)) ? Number(rating) : SCORE_LEVEL_DEFAULTS.A1;
    return ELO_LEVELS.find((level) => score <= SCORE_LEVEL_BANDS[level][1]) || "C2";
  }
  function performanceContextFor(user, targetLang) {
    const lang = String(targetLang || "es").toLowerCase();
    const eloRating = internalEloForUser(user, lang);
    const score = eloToScore(eloRating);
    const curriculumLevels = curriculumLevelsForUser(user, lang);
    const curriculumCefrLevel = curriculumLevels.overall;
    const bucket = user?.learningIntelligence?.[lang] || {};
    const summary = bucket.performanceSummary || {};
    return {
      score,
      eloRating: Math.round(eloRating),
      curriculumCefrLevel,
      curriculumLevels,
      suggestedQuestionLevel: practiceLevelForElo(score),
      ratingGuide: "Elo is the internal 800\u20132200 estimate of demonstrated ability across all CEFR question levels. Score is its 0\u2013100 learner-facing projection; fractional Elo changes accumulate between Score points. Use Elo, recent accuracy and weak concepts to choose challenge and support; keep the curriculum CEFR as the course objective, not a difficulty ceiling. A miss on an easy question is stronger negative evidence than a miss on a hard one. Self-report and placement are initial estimates until practice confirms them.",
      selfReportedStatements: bucket.selfAssessment?.selectedIds || [],
      weakConcepts: (Array.isArray(summary.weakConcepts) ? summary.weakConcepts : []).slice(0, 5),
      recentAccuracy: Array.isArray(summary.recentResults) && summary.recentResults.length ? summary.recentResults.slice(0, 10).reduce((sum, value) => sum + Number(value || 0), 0) / Math.min(10, summary.recentResults.length) : null,
      byLevel: summary.byLevel || {}
    };
  }
  function generationPerformanceContextFor(user, targetLang, { curriculumCefrLevel } = {}) {
    const context = performanceContextFor(user, targetLang);
    const results = user?.learningIntelligence?.[String(targetLang || "es").toLowerCase()]?.performanceSummary?.recentResults;
    return {
      eloRating: context.eloRating,
      eloScale: "800\u20132200; higher means stronger performance across CEFR levels",
      curriculumCefrLevel: curriculumCefrLevel ? normalizeEloLevel(curriculumCefrLevel, context.curriculumCefrLevel) : context.curriculumCefrLevel,
      curriculumLevels: context.curriculumLevels,
      suggestedQuestionLevel: context.suggestedQuestionLevel,
      recentAccuracy: context.recentAccuracy,
      recentAccuracySampleCount: Array.isArray(results) ? Math.min(10, results.length) : 0,
      weakConcepts: context.weakConcepts.slice(0, 3).map(({ concept, questionLevel, misses }) => ({
        concept,
        questionLevel,
        misses
      })),
      byLevel: Object.fromEntries(Object.entries(context.byLevel).filter(([level]) => ELO_LEVELS.includes(level)).map(([level, counts]) => [level, {
        correct: Math.max(0, Number(counts?.correct) || 0),
        missed: Math.max(0, Number(counts?.missed) || 0)
      }])),
      selfReportedStatements: context.selfReportedStatements.slice(0, 10)
    };
  }

  // <stdin>
  function parseLooseJSON(text) {
    const trimmed = String(text || "").trim();
    if (!trimmed) return null;
    try {
      return JSON.parse(trimmed);
    } catch {
    }
    const firstBrace = trimmed.indexOf("{");
    const lastBrace = trimmed.lastIndexOf("}");
    if (firstBrace !== -1 && lastBrace > firstBrace) {
      try {
        return JSON.parse(trimmed.slice(firstBrace, lastBrace + 1));
      } catch {
      }
    }
    const firstBracket = trimmed.indexOf("[");
    const lastBracket = trimmed.lastIndexOf("]");
    if (firstBracket !== -1 && lastBracket > firstBracket) {
      try {
        return JSON.parse(trimmed.slice(firstBracket, lastBracket + 1));
      } catch {
        return null;
      }
    }
    return null;
  }
  function humanizeObjectType(type = "") {
    return String(type || "").replace(/([a-z])([A-Z])/g, "$1 $2").replace(/[_-]+/g, " ").trim().toLowerCase();
  }
  var OBJECT_EXAMINE_FALLBACK_LABELS = {
    en: {
      tree: "tree",
      house: "house",
      building: "building",
      pavilion: "pavilion",
      greenhouse: "greenhouse",
      doorway: "doorway",
      bookshelf: "bookshelf",
      shelf: "shelf",
      tv: "television",
      sofa: "sofa",
      plant: "plant",
      table: "table",
      lamp: "lamp",
      sign: "sign",
      gate: "gate",
      speaker: "speaker",
      balloons: "balloons",
      desk: "desk",
      suitcaseStack: "stack of suitcases",
      counter: "counter",
      stove: "stove",
      fridge: "fridge",
      bench: "bench",
      register: "cash register",
      freezer: "freezer",
      object: "object"
    },
    es: {
      tree: "arbol",
      house: "casa",
      building: "edificio",
      pavilion: "pabellon",
      greenhouse: "invernadero",
      doorway: "entrada",
      bookshelf: "estanteria",
      shelf: "repisa",
      tv: "televisor",
      sofa: "sofa",
      plant: "planta",
      table: "mesa",
      lamp: "lampara",
      sign: "letrero",
      gate: "porton",
      speaker: "altavoz",
      balloons: "globos",
      desk: "escritorio",
      suitcaseStack: "monton de maletas",
      counter: "mostrador",
      stove: "estufa",
      fridge: "refrigerador",
      bench: "banco",
      register: "caja registradora",
      freezer: "congelador",
      object: "objeto"
    },
    pt: {
      tree: "arvore",
      house: "casa",
      building: "predio",
      pavilion: "pavilhao",
      greenhouse: "estufa",
      doorway: "entrada",
      bookshelf: "estante de livros",
      shelf: "prateleira",
      tv: "televisao",
      sofa: "sofa",
      plant: "planta",
      table: "mesa",
      lamp: "luminaria",
      sign: "placa",
      gate: "portao",
      speaker: "caixa de som",
      balloons: "baloes",
      desk: "escrivaninha",
      suitcaseStack: "pilha de malas",
      counter: "balcao",
      stove: "fogao",
      fridge: "geladeira",
      bench: "banco",
      register: "caixa registradora",
      freezer: "freezer",
      object: "objeto"
    },
    it: {
      tree: "albero",
      house: "casa",
      building: "edificio",
      pavilion: "padiglione",
      greenhouse: "serra",
      doorway: "ingresso",
      bookshelf: "libreria",
      shelf: "scaffale",
      tv: "televisore",
      sofa: "divano",
      plant: "pianta",
      table: "tavolo",
      lamp: "lampada",
      sign: "cartello",
      gate: "cancello",
      speaker: "altoparlante",
      balloons: "palloncini",
      desk: "scrivania",
      suitcaseStack: "pila di valigie",
      counter: "bancone",
      stove: "fornello",
      fridge: "frigorifero",
      bench: "panchina",
      register: "cassa",
      freezer: "congelatore",
      object: "oggetto"
    },
    fr: {
      tree: "arbre",
      house: "maison",
      building: "batiment",
      pavilion: "pavillon",
      greenhouse: "serre",
      doorway: "entree",
      bookshelf: "bibliotheque",
      shelf: "etagere",
      tv: "televiseur",
      sofa: "canape",
      plant: "plante",
      table: "table",
      lamp: "lampe",
      sign: "panneau",
      gate: "portail",
      speaker: "haut-parleur",
      balloons: "ballons",
      desk: "bureau",
      suitcaseStack: "pile de valises",
      counter: "comptoir",
      stove: "cuisiniere",
      fridge: "refrigerateur",
      bench: "banc",
      register: "caisse",
      freezer: "congelateur",
      object: "objet"
    },
    ja: {
      tree: "\u6728",
      house: "\u5BB6",
      building: "\u5EFA\u7269",
      pavilion: "\u3042\u305A\u307E\u3084",
      greenhouse: "\u6E29\u5BA4",
      doorway: "\u5165\u53E3",
      bookshelf: "\u672C\u68DA",
      shelf: "\u68DA",
      tv: "\u30C6\u30EC\u30D3",
      sofa: "\u30BD\u30D5\u30A1",
      plant: "\u690D\u7269",
      table: "\u30C6\u30FC\u30D6\u30EB",
      lamp: "\u30E9\u30F3\u30D7",
      sign: "\u770B\u677F",
      gate: "\u9580",
      speaker: "\u30B9\u30D4\u30FC\u30AB\u30FC",
      balloons: "\u98A8\u8239",
      desk: "\u673A",
      suitcaseStack: "\u30B9\u30FC\u30C4\u30B1\u30FC\u30B9\u306E\u5C71",
      counter: "\u30AB\u30A6\u30F3\u30BF\u30FC",
      stove: "\u30B3\u30F3\u30ED",
      fridge: "\u51B7\u8535\u5EAB",
      bench: "\u30D9\u30F3\u30C1",
      register: "\u30EC\u30B8",
      freezer: "\u51B7\u51CD\u5EAB",
      object: "\u7269"
    },
    hi: {
      tree: "\u092A\u0947\u0921\u093C",
      house: "\u0918\u0930",
      building: "\u0907\u092E\u093E\u0930\u0924",
      pavilion: "\u092E\u0902\u0921\u092A",
      greenhouse: "\u0915\u093E\u0901\u091A\u0918\u0930",
      doorway: "\u0926\u094D\u0935\u093E\u0930",
      bookshelf: "\u0915\u093F\u0924\u093E\u092C\u094B\u0902 \u0915\u0940 \u0936\u0947\u0932\u094D\u092B\u093C",
      shelf: "\u0936\u0947\u0932\u094D\u092B\u093C",
      tv: "\u091F\u0947\u0932\u0940\u0935\u093F\u091C\u0928",
      sofa: "\u0938\u094B\u092B\u093C\u093E",
      plant: "\u092A\u094C\u0927\u093E",
      table: "\u092E\u0947\u091C\u093C",
      lamp: "\u0926\u0940\u092A\u0915",
      sign: "\u0938\u0902\u0915\u0947\u0924-\u092A\u091F",
      gate: "\u092B\u093E\u091F\u0915",
      speaker: "\u0938\u094D\u092A\u0940\u0915\u0930",
      balloons: "\u0917\u0941\u092C\u094D\u092C\u093E\u0930\u0947",
      desk: "\u0921\u0947\u0938\u094D\u0915",
      suitcaseStack: "\u0938\u0942\u091F\u0915\u0947\u0938\u094B\u0902 \u0915\u093E \u0922\u0947\u0930",
      counter: "\u0915\u093E\u0909\u0902\u091F\u0930",
      stove: "\u091A\u0942\u0932\u094D\u0939\u093E",
      fridge: "\u092B\u094D\u0930\u093F\u091C",
      bench: "\u092C\u0947\u0902\u091A",
      register: "\u0915\u0948\u0936 \u0930\u091C\u093F\u0938\u094D\u091F\u0930",
      freezer: "\u092B\u093C\u094D\u0930\u0940\u091C\u093C\u0930",
      object: "\u0935\u0938\u094D\u0924\u0941"
    },
    de: {
      tree: "Baum",
      house: "Haus",
      building: "Geb\xE4ude",
      pavilion: "Pavillon",
      greenhouse: "Gew\xE4chshaus",
      doorway: "T\xFCr\xF6ffnung",
      bookshelf: "B\xFCcherregal",
      shelf: "Regal",
      tv: "Fernseher",
      sofa: "Sofa",
      plant: "Pflanze",
      table: "Tisch",
      lamp: "Lampe",
      sign: "Schild",
      gate: "Tor",
      speaker: "Lautsprecher",
      balloons: "Ballons",
      desk: "Schreibtisch",
      suitcaseStack: "Kofferstapel",
      counter: "Theke",
      stove: "Herd",
      fridge: "K\xFChlschrank",
      bench: "Bank",
      register: "Kasse",
      freezer: "Gefrierschrank",
      object: "Objekt"
    }
  };
  var OBJECT_EXAMINE_FALLBACK_SENTENCES = {
    en: (label) => `You notice ${label}.`,
    es: (label) => `Notas ${label}.`,
    pt: (label) => `Voce percebe ${label}.`,
    it: (label) => `Noti ${label}.`,
    fr: (label) => `Tu remarques ${label}.`,
    ja: (label) => `${label}\u306B\u6C17\u3065\u304D\u307E\u3059\u3002`,
    hi: (label) => `\u0906\u092A\u0915\u094B ${label} \u0926\u093F\u0916\u0924\u093E \u0939\u0948\u0964`,
    de: (label) => `Du bemerkst ${label}.`
  };
  function getLocalizedObjectExamineLabel(type = "", lang = "en") {
    const supportLang = normalizeSupportLanguage(lang, DEFAULT_SUPPORT_LANGUAGE);
    const rawType = String(type || "").trim();
    const fallbackLabel = humanizeObjectType(rawType) || OBJECT_EXAMINE_FALLBACK_LABELS.en.object;
    return OBJECT_EXAMINE_FALLBACK_LABELS[supportLang]?.[rawType] || OBJECT_EXAMINE_FALLBACK_LABELS.en?.[rawType] || fallbackLabel;
  }
  function buildFallbackObjectExamineText(object, lang = "en") {
    const supportLang = normalizeSupportLanguage(lang, DEFAULT_SUPPORT_LANGUAGE);
    const name = humanizeObjectType(object?.type) || "object";
    const supportName = getLocalizedObjectExamineLabel(object?.type, supportLang);
    const supportSentence = OBJECT_EXAMINE_FALLBACK_SENTENCES[supportLang] || OBJECT_EXAMINE_FALLBACK_SENTENCES.en;
    return {
      name,
      supportName,
      text: `You notice ${name}.`,
      supportText: supportSentence(supportName)
    };
  }
  var SCENARIO_OBJECT_VISUALS = {
    tree: { width: 1.3, height: 1.6, yOffset: 0.6, z: 2 },
    house: { width: 1.9, height: 2.6, yOffset: 0.68, z: 2.2 },
    building: { width: 1.95, height: 2.7, yOffset: 0.68, z: 2.2 },
    pavilion: { width: 1.75, height: 2, yOffset: 0.62, z: 2.05 },
    greenhouse: { width: 1.8, height: 2.2, yOffset: 0.64, z: 2.1 },
    doorway: { width: 1.35, height: 1.95, yOffset: 0.66, z: 2.08 },
    bookshelf: { width: 1, height: 1.3, yOffset: 0.55, z: 1.9 },
    shelf: { width: 1, height: 1.15, yOffset: 0.52, z: 1.8 },
    counter: { width: 1.65, height: 1.05, yOffset: 0.47, z: 1.82 },
    register: { width: 0.85, height: 0.9, yOffset: 0.44, z: 1.86 },
    stove: { width: 1.05, height: 1.2, yOffset: 0.52, z: 1.84 },
    fridge: { width: 1, height: 1.55, yOffset: 0.62, z: 1.94 },
    freezer: { width: 1.35, height: 0.95, yOffset: 0.46, z: 1.8 },
    bench: { width: 1.45, height: 0.9, yOffset: 0.43, z: 1.76 },
    tv: { width: 1, height: 0.95, yOffset: 0.45, z: 1.7 },
    sofa: { width: 1.2, height: 0.95, yOffset: 0.45, z: 1.7 },
    plant: { width: 0.9, height: 1.1, yOffset: 0.5, z: 1.8 },
    table: { width: 1.1, height: 0.95, yOffset: 0.45, z: 1.7 },
    lamp: { width: 0.75, height: 1.15, yOffset: 0.55, z: 1.8 },
    sign: { width: 0.95, height: 1.15, yOffset: 0.55, z: 1.8 },
    gate: { width: 1, height: 1.15, yOffset: 0.55, z: 1.8 },
    speaker: { width: 0.95, height: 1, yOffset: 0.5, z: 1.8 },
    balloons: { width: 0.95, height: 1.15, yOffset: 0.6, z: 1.9 },
    desk: { width: 1.1, height: 0.95, yOffset: 0.45, z: 1.7 },
    suitcaseStack: { width: 0.95, height: 1, yOffset: 0.48, z: 1.8 },
    default: { width: 1, height: 1, yOffset: 0.5, z: 1.7 }
  };
  function findScenarioObjectAtTile(objects = [], tileX, tileY, options = {}) {
    if (options.exact) {
      return objects.find((object) => object?.tx === tileX && object?.ty === tileY) || null;
    }
    const candidates = objects.map((object) => {
      const visual = SCENARIO_OBJECT_VISUALS[object.type] || SCENARIO_OBJECT_VISUALS.default;
      const halfWidth = Math.max(0, Math.ceil((visual.width - 1) / 2));
      const verticalReach = Math.max(0, Math.ceil(visual.height - 1));
      const hitbox = {
        left: object.tx - halfWidth,
        right: object.tx + halfWidth,
        top: object.ty - verticalReach,
        bottom: object.ty
      };
      const withinHitbox = tileX >= hitbox.left && tileX <= hitbox.right && tileY >= hitbox.top && tileY <= hitbox.bottom;
      if (!withinHitbox) return null;
      return {
        object,
        score: Math.abs(object.tx - tileX) + Math.abs(object.ty - tileY)
      };
    }).filter(Boolean).sort((a, b) => a.score - b.score);
    return candidates[0]?.object || null;
  }
  OBJECT_EXAMINE_FALLBACK_LABELS.ar = {
    tree: "\u0634\u062C\u0631\u0629",
    house: "\u0628\u064A\u062A",
    building: "\u0645\u0628\u0646\u0649",
    pavilion: "\u0645\u0638\u0644\u0629",
    greenhouse: "\u0635\u0648\u0628\u0629",
    doorway: "\u0645\u062F\u062E\u0644",
    bookshelf: "\u0631\u0641 \u0643\u062A\u0628",
    shelf: "\u0631\u0641",
    tv: "\u062A\u0644\u0641\u0632\u064A\u0648\u0646",
    sofa: "\u0643\u0646\u0628\u0629",
    plant: "\u0632\u0631\u0639",
    table: "\u062A\u0631\u0627\u0628\u064A\u0632\u0629",
    lamp: "\u0644\u0645\u0628\u0629",
    sign: "\u0644\u0627\u0641\u062A\u0629",
    gate: "\u0628\u0648\u0627\u0628\u0629",
    speaker: "\u0633\u0645\u0627\u0639\u0629",
    balloons: "\u0628\u0644\u0627\u0644\u064A\u0646",
    desk: "\u0645\u0643\u062A\u0628",
    suitcaseStack: "\u0643\u0648\u0645\u0629 \u0634\u0646\u0637",
    counter: "\u0643\u0627\u0648\u0646\u062A\u0631",
    stove: "\u0628\u0648\u062A\u0627\u062C\u0627\u0632",
    fridge: "\u062A\u0644\u0627\u062C\u0629",
    bench: "\u062F\u0643\u0629",
    register: "\u0643\u0627\u0634\u064A\u0631",
    freezer: "\u0641\u0631\u064A\u0632\u0631",
    object: "\u063A\u0631\u0636"
  };
  OBJECT_EXAMINE_FALLBACK_LABELS.zh = {
    tree: "\u6811",
    house: "\u623F\u5B50",
    building: "\u5EFA\u7B51",
    pavilion: "\u4EAD\u5B50",
    greenhouse: "\u6E29\u5BA4",
    doorway: "\u95E8\u53E3",
    bookshelf: "\u4E66\u67B6",
    shelf: "\u67B6\u5B50",
    tv: "\u7535\u89C6",
    sofa: "\u6C99\u53D1",
    plant: "\u690D\u7269",
    table: "\u684C\u5B50",
    lamp: "\u706F",
    sign: "\u6807\u724C",
    gate: "\u5927\u95E8",
    speaker: "\u626C\u58F0\u5668",
    balloons: "\u6C14\u7403",
    desk: "\u4E66\u684C",
    suitcaseStack: "\u4E00\u645E\u884C\u674E\u7BB1",
    counter: "\u67DC\u53F0",
    stove: "\u7089\u7076",
    fridge: "\u51B0\u7BB1",
    bench: "\u957F\u6905",
    register: "\u6536\u94F6\u673A",
    freezer: "\u51B7\u67DC",
    object: "\u7269\u54C1"
  };
  OBJECT_EXAMINE_FALLBACK_SENTENCES.ar = (label) => `\u0625\u0646\u062A \u0645\u0644\u0627\u062D\u0638 ${label}.`;
  OBJECT_EXAMINE_FALLBACK_SENTENCES.zh = (label) => `\u4F60\u6CE8\u610F\u5230${label}\u3002`;
  var api = { run(op, json) {
    const p = JSON.parse(json || "{}"), scenario = { id: p.scenarioID || "map" }, supportLang = p.support || "en", targetLang = p.target || "es", reviewContext = p.reviewContext || {}, user = p.user || {}, targetLangName = getLanguagePromptName(targetLang) || targetLang, supportLangName = getLanguagePromptName(supportLang) || supportLang, cefrLevel = p.level || reviewContext.cefrLevel || "Pre-A1", adaptiveCefrLevel = reviewContext.isTutorial ? cefrLevel : generationPerformanceContextFor(user, targetLang).suggestedQuestionLevel, useUserStore = { getState: () => ({ user }) };
    const objectExamineCefrPromptRule = (() => {
      const rules = {
        "Pre-A1": "Object examine rule for Pre-A1: use one tiny object-first line. Keep it to a very short noun phrase or simple sentence about the object itself, like 'A big table' or 'It is a table.' No greetings, no roleplay, no people unless the object is a picture of a person.",
        A1: "Object examine rule for A1: use one short, simple sentence about the object itself. Focus on what it is, what it looks like, or what it is for. No greetings, no roleplay, and no unrelated lesson words.",
        A2: "Object examine rule for A2: use one brief, natural observation about the object itself. Keep it concrete and easy to picture.",
        B1: "Object examine rule for B1: use one natural, concrete line about the object itself. Keep it grounded in the environment."
      };
      return rules[adaptiveCefrLevel] || "Write one brief, natural line about the object itself.";
    })();
    const objectExaminePromptContext = (() => [
      reviewContext?.unitTitle ? `Current chapter/unit: ${reviewContext.unitTitle}.` : "",
      reviewContext?.lessonTitles?.length ? `Nearby lesson context: ${reviewContext.lessonTitles.slice(0, 4).join(", ")}.` : "",
      reviewContext?.reviewTerms?.length ? `Optional vocabulary flavor only when it fits the object naturally: ${reviewContext.reviewTerms.slice(0, 12).join(", ")}.` : "",
      "These examine lines are ambient world flavor, not dialogue and not a quiz.",
      "Use the lesson context lightly. Do not force lesson words into every object description."
    ].filter(Boolean).join("\n"))();
    const getObjectExamineKey = (map2, object) => `${map2?.id || scenario?.id || "map"}:${object?.tx ?? 0},${object?.ty ?? 0}:${object?.type || "object"}`;
    const map = p.map || {}, uncachedObjects = p.objects || [], objectExamineCacheRef = { current: /* @__PURE__ */ new Map() };
    let result;
    if (op === "review") result = buildGameReviewContext({ lesson: p.lesson, targetLang: p.target, fallbackLevel: p.level });
    else if (op === "fallback") result = buildFallbackObjectExamineText(p.object, supportLang);
    else if (op === "key") result = getObjectExamineKey(p.map, p.object);
    else if (op === "hit") result = findScenarioObjectAtTile(p.objects || [], p.x, p.y, { exact: p.exact !== false });
    else if (op === "prompt") {
      const mapName = typeof map.name === "string" ? map.name : map.name?.en || map.name?.es || map.name?.pt || map.name?.it || map.name?.fr || map.name?.ja || map.name?.hi || "Area";
      const prompt = [
        objectExamineCefrPromptRule,
        `Live Elo ability context: ${JSON.stringify(generationPerformanceContextFor(useUserStore.getState().user, targetLang))}. Preserve the object's meaning and adjust sentence complexity.`,
        objectExaminePromptContext,
        `Target language: ${targetLangName} (code: ${targetLang}).`,
        `Support language: ${supportLangName} (code: ${supportLang}). Use it ONLY for the supportName and supportText fields.`,
        "You write short 'examine' descriptions for environmental objects in a language-learning RPG.",
        `For each object, write "name" and "text" in ${targetLangName}.`,
        `For each object, write "supportName" as the direct translation of the object name in ${supportLangName}.`,
        `For each object, write "supportText" as the direct translation of the object examine sentence in ${supportLangName}.`,
        "The text sentence should sound like the player quietly noticing the object in the world.",
        "The line must stay about the object itself: what it is, what it looks like, what it is for, or where it sits.",
        "The object should remain the subject of the line. If unsure, write a plain object-first observation.",
        "Keep the object name short and clear.",
        "A little dry or playful humor is welcome, but keep it brief and readable.",
        "Do not mention quests, tasks, controls, objectives, NPCs, greetings, or family-role words unless the object itself directly shows them.",
        "Bad shape: a greeting, a random unit phrase, or a sentence unrelated to the object.",
        "Good shape: a short observation that still makes sense even if the player only sees the object name and the object sprite.",
        ["Pre-A1", "A1"].includes(adaptiveCefrLevel || "") ? "For beginner levels, it is better to be simple and literal than thematic. A direct line like 'It is a table' is better than a clever but off-topic phrase." : "",
        `Current area: ${mapName}.`,
        map?.environment?.summary?.en ? `Area context: ${map.environment.summary.en}.` : "",
        'Return ONLY valid JSON in this exact shape: [{"key":"...","name":"...","supportName":"...","text":"...","supportText":"..."}].',
        `Objects:
${JSON.stringify(
          uncachedObjects.map((object) => ({
            key: getObjectExamineKey(map, object),
            type: object.type,
            typeLabel: humanizeObjectType(object.type),
            x: object.tx,
            y: object.ty
          }))
        )}`
      ].filter(Boolean).join("\n");
      ;
      result = prompt;
    } else if (op === "resolve") {
      const response = p.response || "";
      const parsed = parseLooseJSON(response);
      const entries = Array.isArray(parsed) ? parsed : Array.isArray(parsed?.items) ? parsed.items : [];
      const resolvedTexts = /* @__PURE__ */ new Map();
      entries.forEach((entry) => {
        const key = String(entry?.key || "").trim();
        const name = String(entry?.name || entry?.label || "").trim();
        const supportName = String(
          entry?.supportName || entry?.translation || entry?.supportLabel || ""
        ).trim();
        const supportText = String(
          entry?.supportText || entry?.translatedText || entry?.supportLine || ""
        ).trim();
        const text = String(entry?.text || entry?.line || "").trim();
        if (!key || !text) return;
        resolvedTexts.set(key, {
          name: name.replace(/^["']|["']$/g, "").trim(),
          supportName: supportName.replace(/^["']|["']$/g, "").trim(),
          text: text.replace(/^["']|["']$/g, "").trim(),
          supportText: supportText.replace(/^["']|["']$/g, "").trim()
        });
      });
      uncachedObjects.forEach((object) => {
        const key = getObjectExamineKey(map, object);
        const fallback = buildFallbackObjectExamineText(
          object,
          supportLang
        );
        const resolved = resolvedTexts.get(key);
        const text = resolved ? {
          ...fallback,
          ...resolved,
          name: resolved.name || fallback.name,
          supportName: resolved.supportName || fallback.supportName,
          text: resolved.text || fallback.text,
          supportText: resolved.supportText || fallback.supportText
        } : fallback;
        objectExamineCacheRef.current.set(key, text);
      });
      ;
      result = Object.fromEntries(objectExamineCacheRef.current);
    } else throw Error("Unknown RPG object operation");
    return JSON.stringify(result ?? null);
  } };
  return __toCommonJS(stdin_exports);
})();

PiyaliRPGObjects.api;
