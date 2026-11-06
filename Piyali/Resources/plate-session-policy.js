// Generated from the read-only web App's plate callbacks. Native code owns UI, persistence and activity routing.
(function(){
function buildPlateCelebrationKey(
  langKey = "",
  dayKey = "",
  completed = "",
  progress = null,
) {
  if (!langKey || !dayKey || !completed) return "";
  const progressPart =
    progress && typeof progress.count !== "undefined"
      ? `:${progress.count}`
      : "";
  return `${langKey}:${dayKey}:${completed}${progressPart}`;
}
let scope='',clock=0,nextTimer=0,timers=new Map(),p={},actions=[],lastSnapshot='',plateSnapshot={},plateSessionActive=false,plateCelebration=null;
let platePrevSnapshotRef={current:null},plateConductorArmedRef={current:false},pendingPlateCelebrationRef={current:null},plateCelebrationFlushTimerRef={current:null},plateClearedCelebratedKeyRef={current:''},plateCourseCelebratedKeysRef={current:new Set()},plateCelebrationBlockersRef={current:{}},lessonCompletionSequenceActiveRef={current:false},pendingLessonCompletionRef={current:null},pendingDailyGoalCelebrationRef={current:null},pendingTutorialBitcoinModalRef={current:null};
const Date={now:()=>clock},document={},window={setTimeout:(fn,delay)=>{const id=++nextTimer;timers.set(id,{at:clock+(Number(delay)||0),fn});return id},clearTimeout:id=>timers.delete(id),dispatchEvent:event=>actions.push({type:'courseComplete',kind:event.detail.kind})},setTimeout=window.setTimeout,clearTimeout=window.clearTimeout;
function CustomEvent(type,{detail}){this.type=type;this.detail=detail;}
const useModalStore={getState:()=>({})},isTutorCompletionSequencePending=()=>false,hasVisibleChakraModalSurface=()=>false;
const playSound=name=>actions.push({type:'sound',name}),setPlateCelebration=value=>{plateCelebration=typeof value==='function'?value(plateCelebration):value;plateCelebrationBlockersRef.current.plateCelebrationOpen=!!plateCelebration;},endPlateSession=()=>{plateSessionActive=false;actions.push({type:'endSession'})},getNextPlateCourse=snap=>snap.courses.find(c=>!c.done)?.kind||null,getGoalCompletionDetails=()=>p.goalDetails||null,getRepairCompletionDetails=()=>p.repairDetails||null;
const navigateToPlateCourse=course=>actions.push({type:'navigate',course}),goToSkillTreeMode=mode=>actions.push({type:'surface',mode});
let viewMode='skillTree',activeLesson=null;
const flushPlateCelebrationWhenQuiet=() => {
    if (plateCelebrationFlushTimerRef.current) {
      clearTimeout(plateCelebrationFlushTimerRef.current);
      plateCelebrationFlushTimerRef.current = null;
    }
    const startedAt = Date.now();
    // `expectsModal` only controls the initial grace window for completion
    // chains that may mount a beat late. The poll below still waits behind any
    // modal or pending modal state that actually exists.
    const expectsModal = Boolean(
      pendingPlateCelebrationRef.current?.expectsModal,
    );
    const chain = { sawModal: false, quietChecks: 0 };

    const showQueued = () => {
      const queued = pendingPlateCelebrationRef.current;
      pendingPlateCelebrationRef.current = null;
      if (!queued) return;
      setPlateCelebration((prev) => prev || queued);
      // Celebratory sound, timed to the modal's appearance: dedicated Tone.js
      // synths — a cute "ta-da" for a single objective, a grand flourish when
      // the whole daily is cleared. Played by name (not via the shared mp3->
      // tone map) so each is unique to the quest flow.
      playSound(queued.type === "cleared" ? "questCleared" : "questComplete");
    };

    const hasBlockingModalSurface = () => {
      const blockers = plateCelebrationBlockersRef.current || {};
      const modalStore = useModalStore.getState?.() || {};
      return Boolean(
        lessonCompletionSequenceActiveRef.current ||
        isTutorCompletionSequencePending() ||
        pendingLessonCompletionRef.current ||
        pendingDailyGoalCelebrationRef.current ||
        pendingTutorialBitcoinModalRef.current ||
        modalStore.dailyGoalOpen ||
        modalStore.timerModalOpen ||
        Object.values(blockers).some(Boolean) ||
        hasVisibleChakraModalSurface(),
      );
    };

    const tick = () => {
      plateCelebrationFlushTimerRef.current = null;
      if (!pendingPlateCelebrationRef.current) return;
      if (typeof document === "undefined" || typeof window === "undefined") {
        showQueued();
        return;
      }
      if (hasBlockingModalSurface()) {
        chain.sawModal = true;
        chain.quietChecks = 0;
        plateCelebrationFlushTimerRef.current = setTimeout(tick, 120);
        return;
      }
      // Wait for a not-yet-mounted completion chain only when one is expected
      // (the Tutor can mount its modal late while audio settles).
      if (expectsModal && !chain.sawModal && Date.now() - startedAt < 2500) {
        plateCelebrationFlushTimerRef.current = setTimeout(tick, 250);
        return;
      }
      // Once a chain was seen, require two consecutive quiet checks so the gap
      // between chained modals doesn't fire early.
      chain.quietChecks += 1;
      const needed = chain.sawModal ? 2 : 1;
      if (chain.quietChecks < needed) {
        plateCelebrationFlushTimerRef.current = setTimeout(tick, 250);
        return;
      }
      showQueued();
    };

    plateCelebrationFlushTimerRef.current = setTimeout(
      tick,
      expectsModal ? 400 : 100,
    );
  };
const requestPlateCelebration=(celebration) => {
      if (celebration?.type === "cleared") {
        // The cleared celebration can be requested by both the conductor and
        // the bonus-claim effect — show it once per plate.
        const onceKey = `${plateSnapshot.langKey}:${plateSnapshot.dayKey}`;
        if (plateClearedCelebratedKeyRef.current === onceKey) return;
        plateClearedCelebratedKeyRef.current = onceKey;
      }
      if (celebration?.type === "course" && celebration.completed) {
        const courseKey = buildPlateCelebrationKey(
          plateSnapshot.langKey,
          plateSnapshot.dayKey,
          celebration.completed,
          celebration.progress,
        );
        if (courseKey) {
          if (plateCourseCelebratedKeysRef.current.has(courseKey)) return;
          plateCourseCelebratedKeysRef.current.add(courseKey);
        }
      }
      pendingPlateCelebrationRef.current = celebration;
      flushPlateCelebrationWhenQuiet();
    };
const observe=() => {
    const prev = platePrevSnapshotRef.current;
    platePrevSnapshotRef.current = plateSnapshot;
    if (!prev) return;
    // Only celebrate genuine in-session completions, not hydration transitions.
    if (!plateConductorArmedRef.current) {
      plateSnapshot.courses.forEach((c) => {
        if (c.done) {
          const key = buildPlateCelebrationKey(
            plateSnapshot.langKey,
            plateSnapshot.dayKey,
            c.kind,
          );
          if (key) plateCourseCelebratedKeysRef.current.add(key);
        }
      });
      return;
    }
    if (
      prev.dayKey !== plateSnapshot.dayKey ||
      prev.langKey !== plateSnapshot.langKey
    )
      return;

    const justDone = plateSnapshot.courses
      .map((course) => course.kind)
      .find(
        (kind) => plateSnapshot.byKind[kind]?.done && !prev.byKind[kind]?.done,
      );
    if (!justDone) {
      // Repair advances one step at a time. Intermediate steps switch directly
      // to the next modality; only the completed Repair bundle is celebrated.
      const prevRepair = prev.byKind?.repair;
      const nowRepair = plateSnapshot.byKind?.repair;
      const repairStepped =
        nowRepair &&
        prevRepair &&
        !nowRepair.done &&
        nowRepair.count > prevRepair.count;
      if (!repairStepped) return;
      window.setTimeout(() => {
        void navigateToPlateCourse("repair");
      }, 0);
      return;
    }

    const courseKey = buildPlateCelebrationKey(
      plateSnapshot.langKey,
      plateSnapshot.dayKey,
      justDone,
    );
    if (courseKey && plateCourseCelebratedKeysRef.current.has(courseKey))
      return;

    const next = getNextPlateCourse(plateSnapshot);
    const details =
      justDone === "goal"
        ? getGoalCompletionDetails()
        : justDone === "repair"
          ? getRepairCompletionDetails(plateSnapshot.byKind?.repair?.count)
          : null;
    // Only ordinary lesson/Tutor courses render their own completion modal.
    // Goal and Repair modalities are silent until their entire bundle is done.
    const expectsModal = justDone === "learn" || justDone === "speak";

    // Live voice surfaces are keep-alive across mode switches, so finishing
    // the Conversation course would otherwise leave the session talking under
    // the task-complete modal and even after Continue navigates onward. In a
    // guided session, tell the surface its course is done so it can hang up
    // before the celebration lands.
    if (plateSessionActive && typeof window !== "undefined") {
      window.dispatchEvent(
        new CustomEvent("plate:courseComplete", {
          detail: { kind: justDone },
        }),
      );
    }

    if (!plateSessionActive) {
      // Standalone acknowledgement for any course finished outside a guided
      // session (a lesson, a Tutor lesson, or flashcards). The celebration
      // queue waits for the surface's own completion modal to close first, so
      // it chains after it rather than overlapping. Skip when this completion
      // clears the whole plate — the bonus effect celebrates that instead.
      if (next) {
        requestPlateCelebration({
          type: "course",
          completed: justDone,
          next: null,
          expectsModal,
          details,
        });
      }
      return;
    }

    if (!next) {
      endPlateSession();
      // Don't navigate yet — show the cleared modal where the user is, then
      // return home when they dismiss it (navigateHome handled on close).
      requestPlateCelebration({
        type: "cleared",
        navigateHome: true,
        expectsModal,
        details,
      });
      return;
    }
    // Queued: renders after the surface's own completion-modal chain
    // (lesson celebration, Tutor agenda modals, daily-goal celebration).
    // Navigation to the next course happens on its Continue button.
    requestPlateCelebration({
      type: "course",
      completed: justDone,
      next,
      expectsModal,
      details,
    });
  };
const handlePlateCelebrationContinue=() => {
    const celebration = plateCelebration;
    setPlateCelebration(null);
    // A finished ephemeral repair lesson stays on screen behind the
    // celebration (its completion deliberately doesn't navigate) — so when
    // there's no next course to move to, Continue must still leave the spent
    // lesson rather than strand the learner on it.
    const finishedRepairLesson =
      viewMode === "lesson" &&
      Boolean(activeLesson?.isRepair || activeLesson?.isGoal);
    if (celebration?.type === "course" && celebration.next) {
      navigateToPlateCourse(celebration.next);
    } else if (
      (celebration?.type === "cleared" && celebration.navigateHome) ||
      finishedRepairLesson
    ) {
      goToSkillTreeMode("plate");
    }
  };
function reset(next){scope=next;timers.clear();platePrevSnapshotRef.current=null;plateConductorArmedRef.current=false;pendingPlateCelebrationRef.current=null;plateCelebrationFlushTimerRef.current=null;plateClearedCelebratedKeyRef.current='';plateCourseCelebratedKeysRef.current=new Set();plateCelebration=null;lastSnapshot='';window.setTimeout(()=>{plateConductorArmedRef.current=true},2000);}
return {run:function(op,input){p=JSON.parse(input||'{}');clock=Number(p.now)||0;actions=[];if(scope!==p.scope)reset(p.scope);plateSnapshot=p.snapshot||{courses:[],byKind:{}};plateSessionActive=!!p.guided;viewMode=p.ephemeralLesson?'lesson':'skillTree';activeLesson=p.ephemeralLesson?{isRepair:true}:null;plateCelebrationBlockersRef.current={native:!!p.blocked,plateCelebrationOpen:!!plateCelebration};
if(op==='continue')handlePlateCelebrationContinue();else if(op==='step'){const encoded=JSON.stringify(plateSnapshot);if(lastSnapshot!==encoded){lastSnapshot=encoded;observe();}if(p.bonusJustClaimed)requestPlateCelebration({type:'cleared'});const due=[...timers].filter(([,v])=>v.at<=clock).sort((a,b)=>a[1].at-b[1].at||a[0]-b[0]);for(const[id,timer]of due){if(timers.delete(id))timer.fn();}}
else throw Error('Unknown plate operation '+op);
return JSON.stringify({pending:pendingPlateCelebrationRef.current,visible:plateCelebration,actions,nextWake:timers.size?Math.min(...[...timers.values()].map(v=>v.at)):null,armed:plateConductorArmedRef.current});}};})()