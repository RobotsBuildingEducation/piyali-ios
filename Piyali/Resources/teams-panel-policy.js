var PiyaliTeamsPanel = (() => {
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

  // team-relays:team-relays
  var TEAM_RELAYS = ["wss://relay.primal.net", "wss://relay.ditto.pub", "wss://nos.lol"];

  // ../nosabos/nosabos/src/utils/reconcileTeams.js
  var reconcileUserTeams = ({
    createdTeams = [],
    memberTeams = [],
    nostrTeams = null,
    userNpub,
    onPruneInvite = () => {
    }
  }) => {
    const nostrTeamsLoaded = Array.isArray(nostrTeams);
    const activeNostrTeamMap = new Map((nostrTeams || []).map((t) => [t.id, t]));
    const fromNostr = (nostrTeams || []).map((team) => ({
      id: team.id,
      teamName: team.name,
      createdBy: team.createdBy,
      isCreator: team.createdBy === userNpub,
      members: team.members.filter((npub) => npub !== team.createdBy).map((npub) => ({ npub, status: "accepted" })),
      nostr: { id: team.id, identifier: team.identifier, relays: TEAM_RELAYS },
      nostrCreatedAt: team.createdAt
    }));
    const validMemberTeams = memberTeams.filter(Boolean).filter((team) => {
      const isNostrTeam = Boolean(team.nostr);
      if (!isNostrTeam) return true;
      if (!nostrTeamsLoaded) return true;
      const onNostr = activeNostrTeamMap.has(team.id);
      if (!onNostr) {
        onPruneInvite(team.id);
        return false;
      }
      return true;
    });
    const validCreatedTeams = createdTeams.filter(Boolean);
    const allTeams = [...fromNostr, ...validCreatedTeams, ...validMemberTeams];
    const deduped = [];
    for (const team of allTeams) {
      if (!team) continue;
      const existing = deduped.find((entry) => entry.id === team.id && entry.createdBy === team.createdBy);
      if (!existing) {
        deduped.push({ ...team });
        continue;
      }
      if (team.creatorName && !existing.creatorName) existing.creatorName = team.creatorName;
      if (team.isCreator) existing.isCreator = true;
      if (team.nostr && !existing.nostr) existing.nostr = team.nostr;
    }
    return deduped;
  };

  // ../nosabos/nosabos/src/features/stories/storyCharacters.js
  var RPG_STORY_CHARACTERS = [
    {
      id: "hamster",
      name: "Sheilfer",
      role: "radio host / narrator",
      voice: "echo",
      personality: "the narrator of the app, a relaxed but confident male voice guiding the experience",
      portraitIndex: "33",
      portraitPool: ["33", "26", "25", "22"]
    },
    {
      id: "frog",
      name: "Jiraiya",
      role: "wise elder / toad sage",
      voice: "ash",
      personality: "an ancient male toad sage, wise and measured with a deep gravelly tone",
      portraitIndex: "29",
      portraitPool: ["29", "32", "36"]
    },
    {
      id: "purple-girl",
      name: "Yoruichi",
      role: "spirited martial artist / cheerful adventurer",
      voice: "marin",
      personality: "a joyful woman with a Japanese accent, warm and enthusiastic",
      portraitIndex: "31",
      portraitPool: ["31", "39", "34"]
    },
    {
      id: "cat",
      name: "Neko",
      role: "witty companion / playful feline",
      voice: "sage",
      personality: "a sarcastic female cat humanoid, dry wit and playful disdain in every word",
      portraitIndex: "40",
      portraitPool: ["40", "38", "37", "28", "24"]
    },
    {
      id: "yachiru",
      name: "Yachiru",
      role: "cheerful companion / energetic friend",
      voice: "shimmer",
      personality: "an adorable, bubbly companion with childlike energy, excitable, warm, and playful",
      portraitIndex: "18",
      portraitPool: ["18", "20", "21", "23", "27", "30", "35"]
    }
  ];

  // <stdin>
  var characterImagesMap = Object.fromEntries(Array.from({ length: 100 }, (_, i) => [String(i), "story-portrait-" + i + ".webp"]));
  var getAvatarCharacter = (profile) => {
    const authorId = String(
      profile?.pubkey || profile?.npub || profile?.profile?.pubkey || profile?.id || "nostr-friend"
    );
    let hash = 2166136261;
    for (let i = 0; i < authorId.length; i += 1) {
      hash ^= authorId.charCodeAt(i);
      hash = Math.imul(hash, 16777619);
    }
    const character = RPG_STORY_CHARACTERS[(hash >>> 0) % RPG_STORY_CHARACTERS.length];
    const portraitPool = character?.portraitPool || [character?.portraitIndex || "35"];
    const portraitId = portraitPool[(hash >>> 5 >>> 0) % portraitPool.length];
    return characterImagesMap[portraitId] || characterImagesMap["35"];
  };
  var sanitizeProfiles = (profiles = []) => {
    const bannedNames = /* @__PURE__ */ new Set(["data", "test", "hi", "text", "hii"]);
    return profiles.filter((item) => {
      const name = item?.profile?.name?.toLowerCase();
      return !name || !bannedNames.has(name);
    }).sort((a, b) => (b?.createdAt || 0) - (a?.createdAt || 0));
  };
  var api = { run(op, json) {
    const p = JSON.parse(json || "{}");
    let result;
    if (op === "reconcile") {
      const pruned = [];
      result = { teams: reconcileUserTeams({ ...p, onPruneInvite: (id) => pruned.push(id) }), pruned };
    } else if (op === "addMember") {
      let memberNpub = p.input || "", membersToInvite = p.members || [], notice = null;
      const t = p.copy || {}, toast = (value) => notice = value, setMemberNpub = (value) => memberNpub = value, setMembersToInvite = (fn) => membersToInvite = fn(membersToInvite);
      (() => {
        if (!memberNpub.trim()) {
          toast({
            title: t?.teams_create_error || "Error",
            description: t?.teams_create_invalid || "Please enter a valid npub to invite",
            status: "error"
          });
          return;
        }
        if (!memberNpub.startsWith("npub")) {
          toast({
            title: t?.teams_create_error || "Error",
            description: t?.teams_create_invalid_format || "Invalid npub format. npubs begin with 'npub'",
            status: "error"
          });
          return;
        }
        if (membersToInvite.includes(memberNpub.trim())) {
          toast({
            title: t?.teams_create_error || "Error",
            description: t?.teams_create_duplicate || "This npub is already on the list",
            status: "warning"
          });
          return;
        }
        setMembersToInvite((prev) => [...prev, memberNpub.trim()]);
        setMemberNpub("");
      })();
      result = { input: memberNpub, members: membersToInvite, notice };
    } else if (op === "feedAvatar") result = getAvatarCharacter(p.profile);
    else if (op === "feedSanitize") result = sanitizeProfiles(p.profiles);
    else if (op === "feedCard") {
      const TOTAL_FEED_STEPS = 120, profile = p.profile || {}, extractQuestionNumber = (text = "") => {
        const match = text.match(/question (\d+)/i);
        return match ? Number(match[1]) : null;
      };
      result = (() => {
        const questionNumber = extractQuestionNumber(profile.content || "");
        const hasScholarship = (profile.content || "").toLowerCase().includes("a new scholarship");
        const noSaboProgressTagged = profile.tags?.some(
          (tag) => tag?.[0] === "purpose" && tag?.[1] === "nosaboProgress"
        );
        const noSaboProgressContent = (profile.content || "").toLowerCase().includes("i just reached");
        const noSaboProgress = noSaboProgressTagged || noSaboProgressContent;
        if (!questionNumber && !hasScholarship && !noSaboProgress) return null;
        const progressValue = questionNumber ? Math.min(100, questionNumber / TOTAL_FEED_STEPS * 100) : 0;
        ;
        if (questionNumber) return { kind: "question", question: questionNumber, percent: progressValue };
        if (noSaboProgress) {
          const tagValue = (key) => profile.tags?.find((entry) => entry?.[0] === key)?.[1] ?? null;
          const totalXp = Number(tagValue("total_xp"));
          const percentValue = Number(tagValue("daily_goal_percent"));
          const dailyGoalPercent = Number.isFinite(percentValue) ? Math.max(0, Math.min(100, percentValue)) : null;
          ;
          return { kind: "progress", totalXP: Number.isFinite(totalXp) ? totalXp : questionNumber || questionNumber === 0 ? questionNumber : null, percent: dailyGoalPercent };
        }
        return null;
      })();
    } else if (op === "view") {
      const myTeams = p.teams || [], teamInvites = p.invites || [];
      const pendingInvites = teamInvites.filter(
        (invite) => invite.status === "pending"
      );
      result = { single: myTeams.length === 1, pending: pendingInvites, teams: myTeams.map((team) => ({ id: team.id, progress: (p.rows?.[team.id] || []).slice().sort((a, b) => Number(Boolean(b.isCreator)) - Number(Boolean(a.isCreator))), accepted: (team.members || []).filter((m) => m.status === "accepted").length + 1, pending: (team.members || []).filter((m) => m.status === "pending") })) };
    } else throw Error("Unknown Teams panel operation");
    return JSON.stringify(result ?? null);
  } };
  return __toCommonJS(stdin_exports);
})();

PiyaliTeamsPanel.api;
