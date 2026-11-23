import { readFile } from "node:fs/promises";
import path from "node:path";
import { createRequire } from "node:module";

export async function lessonCompletionFixture(root, reference) {
  const require = createRequire(path.join(reference, "package.json"));
  const { parse } = require("@babel/parser");
  const traverse = require("@babel/traverse").default;
  const source = await readFile(path.join(reference, "src/App.jsx"), "utf8");
  let modal, copy;
  traverse(parse(source, { sourceType: "module", plugins: ["jsx"] }), {
    JSXElement({ node }) {
      const open = node.openingElement;
      if (open.name.name !== "Modal") return;
      if (open.attributes.some(attr => attr.name?.name === "isOpen" && attr.value?.expression?.name === "showCompletionModal")) {
        modal = source.slice(node.start, node.end);
      }
    },
    VariableDeclarator({ node }) {
      if (node.id.name === "uiCopy") copy = source.slice(node.start, node.end);
    },
  });
  const start = source.indexOf("  const [hasRoomyPhoneViewport]");
  const end = source.indexOf("  const [showTutorialBitcoinModal", start);
  if (!modal || !copy || start < 0 || end < start) throw Error("The source lesson completion moved");
  const viewport = source.slice(start, end);
  const route = "/__piyali-lesson-completion", module = route + ".jsx";
  const entry = path.join(root, "scripts", module.slice(1));
  return {
    name: "piyali-source-lesson-completion",
    enforce: "pre",
    resolveId(id) { if (id === module) return entry; },
    load(id) {
      if (id !== entry) return;
      return `
import React,{useState} from "react";
import {createRoot} from "react-dom/client";
import {ChakraProvider,Modal,ModalOverlay,ModalContent,ModalBody,VStack,Box,Text,Button,useMediaQuery,useBreakpointValue} from "@chakra-ui/react";
import {theme} from "/src/theme";
import "/src/index.css";
import {useThemeStore} from "/src/useThemeStore";
import {normalizeSupportLanguage,DEFAULT_SUPPORT_LANGUAGE} from "/src/constants/languages";
import {getGermanCopy} from "/src/utils/germanCopy";
import {nativeModalMotionProps,nativeOverlayMotionProps} from "/src/utils/modalMotion";
import RandomCharacter from "/src/components/RandomCharacter";
import XpProgressHeader from "/src/components/XpProgressHeader";
const ${copy};
const q=new URLSearchParams(location.search);
const appLanguage=q.get("language")||"en",resolvedTargetLang="es";
const title=q.has("title")?JSON.parse(q.get("title")):{en:"Getting Started",ar:"البداية"};
const completedLessonData={lessonId:"lesson-tutorial-1",targetLang:"es",title,xpEarned:Number(q.get("reward")??50),totalXp:Number(q.get("snapshot")??50)};
const userProgress={totalXp:Number(q.get("progress")??0)};
const useUserStore={getState:()=>({user:{progress:{es:Number(q.get("live")??0)}}})};
const getLanguageXp=(progress,target)=>progress[target]||0;
useThemeStore.getState().syncThemeMode(q.get("theme")==="dark"?"dark":"light");
document.documentElement.dir=appLanguage==="ar"?"rtl":"ltr";
function Preview(){
  const [showCompletionModal,setOpen]=useState(true);
  ${viewport}
  const handleCloseCompletionModal=()=>{setOpen(false);window.__piyaliLessonCompletionClosed=true;};
  return <Box minH="100dvh" bg="var(--app-page-bg)">${modal}</Box>;
}
createRoot(document.getElementById("root")).render(<ChakraProvider theme={theme}><Preview/></ChakraProvider>);
`;
    },
    configureServer(server) {
      server.middlewares.use(route, async (req, res, next) => {
        if ((req.originalUrl || req.url).split("?")[0].endsWith(".jsx")) return next();
        const html = await server.transformIndexHtml(route, `<!doctype html><html><head><meta name="viewport" content="width=device-width,initial-scale=1"></head><body><div id="root"></div><script type="module" src="${module}"></script></body></html>`);
        res.setHeader("Content-Type", "text/html");
        res.end(html);
      });
    },
  };
}
