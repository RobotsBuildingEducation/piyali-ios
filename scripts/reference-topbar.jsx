// Generated from the unmodified source header. Public QA fixtures only.
import React from 'react';
import {Box,HStack,IconButton,Text,Spacer} from '@chakra-ui/react';
import {FaCalendarAlt,FaCalendarCheck} from 'react-icons/fa';
import {MdShowChart} from 'react-icons/md';
import {FiClock,FiPause,FiPlay} from 'react-icons/fi';
import GlassContainer from '/src/components/GlassContainer';
import {WaveBar} from '/src/components/WaveBar';
import SessionTimerBadge from '/src/components/SessionTimerBadge';
import {setRemainingSeconds} from '/src/provider/SessionTimerProvider';
import {useThemeStore} from '/src/useThemeStore';
export default function SourceTopBar({appLanguage='en',dailyXp=0,dailyGoalXp=100,hasTimer=false,timerPaused=false,onOpenDailyGoalModal=()=>{},onOpenTimerModal=()=>{},onTogglePauseTimer=()=>{}}){
const themeMode=useThemeStore(s=>s.themeMode),showUpdateBar=false,isTimerRunning=hasTimer&&!timerPaused,timerDurationSeconds=1200;setRemainingSeconds(hasTimer?600:null);
const uiCopy=(language,values)=>values[language]||values.en;
const getTopBarPressProps=(key,action)=>({onClick:action});
const topBarControlProps = {
    size: "sm",
    w: "32px",
    h: "32px",
    minW: "32px",
    p: 0,
    borderRadius: "13px",
    style: { cornerShape: "superellipse(1.6)" },
  };
const dailyRawPct =
    dailyGoalXp > 0
      ? Math.max(0, Math.round((dailyXp / dailyGoalXp) * 100))
      : 0;
const dailyDone = dailyGoalXp > 0 && dailyXp >= dailyGoalXp;
const dailyGoalHudColor =
    dailyRawPct >= 100
      ? themeMode === "light"
        ? "#39BFD1"
        : "#2dd4bf"
      : dailyRawPct > 50
        ? themeMode === "light"
          ? "#6d28d9"
          : "#b794f4"
        : themeMode === "light"
          ? "#4b5563"
          : "whiteAlpha.700";
const dailyGoalHudTextColor =
    themeMode === "light" && dailyRawPct >= 100 ? "#167F91" : dailyGoalHudColor;
const dailyGoalLabel = uiCopy(appLanguage, {
    en: "Daily XP",
    es: "XP diaria",
    pt: "XP diária",
    fr: "XP du jour",
    it: "XP giornaliera",
    de: "Tägliche XP",
    ja: "今日のXP",
    zh: "每日 XP",
    ru: "Ежедневный XP",
    ar: "XP اليومية",
    hi: "दैनिक XP",
  });
return (<Box
        as="header"
        position="sticky"
        top={0}
        zIndex={100}
        w="100%"
        borderBottom={themeMode === "light" ? "none" : "1px solid #000026ff"}
      >
        <GlassContainer
          borderRadius={0}
          blur={0.5}
          contrast={1.2}
          brightness={1.05}
          saturation={1.1}
          zIndex={100}
        >
          {showUpdateBar ? (
            <AppUpdateTopBar
              language={appLanguage}
              isApplying={uiState === "applying"}
              onUpdate={async () => {
                const ok = await applyUpdate();
                if (!ok && errorMessage) {
                  toast({
                    title: "Update notice",
                    description: errorMessage,
                    status: "info",
                    duration: 4000,
                    isClosable: true,
                  });
                }
              }}
            />
          ) : (
            <HStack
              w="100%"
              px={{ base: 2, md: 3 }}
              pt="calc(env(safe-area-inset-top, 0px) + 0.5rem)"
              pb={2}
              color="gray.100"
              wrap="wrap"
              spacing={{ base: 2, md: 3 }}
            >
              {/* LEFT: Daily Goal button + Daily XP status */}
              <HStack
                spacing={{ base: 1, md: 1.5 }}
                minW={0}
                flex="1 1 auto"
                align="center"
              >
                <IconButton
                  {...topBarControlProps}
                  variant="outline"
                  colorScheme="teal"
                  icon={dailyDone ? <FaCalendarCheck /> : <FaCalendarAlt />}
                  aria-label={uiCopy(appLanguage, {
                    en: "Open daily goal",
                    es: "Abrir meta diaria",
                    it: "Apri obiettivo giornaliero",
                    ja: "デイリー目標を開く",
                    zh: "打开每日目标",
                  })}
                  borderColor="teal.600"
                  _active={{ transform: "none" }}
                  {...getTopBarPressProps("daily-goal", onOpenDailyGoalModal)}
                />
                <HStack
                  spacing={{ base: 0.5, md: 0.5 }}
                  h="34px"
                  minW={0}
                  px={0}
                  align="center"
                  color={dailyGoalHudColor}
                  title={`${dailyGoalLabel}: ${dailyRawPct}%`}
                >
                  <Box
                    as={MdShowChart}
                    boxSize={{ base: 4, md: 4.5 }}
                    flexShrink={0}
                  />
                  <Text
                    fontSize={{ base: "xs", md: "xs" }}
                    fontWeight="bold"
                    color={dailyGoalHudTextColor}
                    lineHeight="1.2"
                    whiteSpace="nowrap"
                    maxW={{ base: "92px", sm: "140px", md: "none" }}
                    overflow="hidden"
                    textOverflow="ellipsis"
                  >
                    {dailyGoalLabel}
                  </Text>
                  <Box
                    w={{ base: "72px", sm: "96px", md: "120px" }}
                    flexShrink={0}
                    role="progressbar"
                    aria-label={dailyGoalLabel}
                    aria-valuemin={0}
                    aria-valuemax={100}
                    aria-valuenow={Math.min(100, dailyRawPct)}
                  >
                    <WaveBar
                      value={dailyRawPct}
                      height={12}
                      bg={
                        themeMode === "light"
                          ? "rgba(255, 255, 255, 0.58)"
                          : "rgba(255,255,255,0.22)"
                      }
                      border={
                        themeMode === "light"
                          ? "rgba(91, 75, 58, 0.10)"
                          : "rgba(255,255,255,0.14)"
                      }
                    />
                  </Box>
                </HStack>
              </HStack>

              <Spacer display={{ base: "none", md: "block" }} />

              {/* RIGHT: controls */}
              <HStack spacing={3} flexShrink={0} ml="auto" align="center">
                <Box position="relative" flexShrink={0}>
                  {hasTimer && (
                    <SessionTimerBadge
                      durationSeconds={timerDurationSeconds}
                      isRunning={isTimerRunning}
                    />
                  )}
                  <IconButton
                    {...topBarControlProps}
                    colorScheme="teal"
                    variant={isTimerRunning ? "solid" : "outline"}
                    icon={<FiClock />}
                    boxShadow={isTimerRunning ? "none" : undefined}
                    aria-label={uiCopy(appLanguage, {
                      en: "Open timer",
                      es: "Abrir temporizador",
                      it: "Apri timer",
                      ja: "タイマーを開く",
                      zh: "打开计时器",
                    })}
                    _hover={isTimerRunning ? { boxShadow: "none" } : undefined}
                    _active={{ boxShadow: "none", transform: "none" }}
                    {...getTopBarPressProps("session-timer", onOpenTimerModal)}
                  />
                </Box>
                {hasTimer && (
                  <IconButton
                    {...topBarControlProps}
                    colorScheme="teal"
                    variant={timerPaused ? "outline" : "ghost"}
                    icon={timerPaused ? <FiPlay /> : <FiPause />}
                    aria-label={
                      timerPaused
                        ? uiCopy(appLanguage, {
                            en: "Resume timer",
                            es: "Reanudar temporizador",
                            it: "Riprendi timer",
                            ja: "タイマーを再開",
                            zh: "继续计时器",
                          })
                        : uiCopy(appLanguage, {
                            en: "Pause timer",
                            es: "Pausar temporizador",
                            it: "Metti in pausa il timer",
                            ja: "タイマーを一時停止",
                            zh: "暂停计时器",
                          })
                    }
                    {...getTopBarPressProps(
                      "session-timer-toggle",
                      onTogglePauseTimer,
                    )}
                  />
                )}
              </HStack>
            </HStack>
          )}
        </GlassContainer>
      </Box>);
}
