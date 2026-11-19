(()=>{var OriginalStoryFeedback = (() => {
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
    speechReasonTips: () => speechReasonTips
  });

  // ../nosabos/nosabos/src/components/flagsIcons/flags.jsx
  var mexicanFlagCounter = 0;
  var egyptianFlagCounter = 0;
  var chineseFlagCounter = 0;
  var mexicanFlag = () => {
    const id = `MX_svg__${++mexicanFlagCounter}`;
    return /* @__PURE__ */ React.createElement("svg", { width: 24, height: 24, fill: "none", viewBox: "0 0 24 24" }, /* @__PURE__ */ React.createElement("g", { clipPath: `url(#${id})` }, /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
        fill: "#F0F0F0"
      }
    ), /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M24 12a12 12 0 0 0-6.783-10.81v21.62A12 12 0 0 0 23.999 12Z",
        fill: "#D80027"
      }
    ), /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M0 12a12 12 0 0 0 6.783 10.809V1.19A12 12 0 0 0 0 12Zm8.87 0a3.13 3.13 0 0 0 6.261 0v-1.044h-6.26v1.043Z",
        fill: "#6DA544"
      }
    ), /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M16.173 9.913h-3.13a1.044 1.044 0 0 0-2.087 0h-3.13c0 .577.501 1.044 1.077 1.044H8.87c0 .576.467 1.043 1.043 1.043 0 .577.467 1.044 1.044 1.044h2.087c.576 0 1.043-.467 1.043-1.044.576 0 1.044-.467 1.044-1.043h-.035c.576 0 1.078-.467 1.078-1.044Z",
        fill: "#FF9811"
      }
    )), /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" }))));
  };
  var netherlandsFlag = () => {
    return /* @__PURE__ */ React.createElement("svg", { width: 24, height: 24, fill: "none", viewBox: "0 0 24 24" }, /* @__PURE__ */ React.createElement("g", { clipPath: "url(#NL_svg__a)" }, /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
        fill: "#F0F0F0"
      }
    ), /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M12 0C6.84 0 2.442 3.256.746 7.826h22.507C21.558 3.256 17.16 0 12 0Z",
        fill: "#A2001D"
      }
    ), /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M12 24c5.16 0 9.558-3.256 11.253-7.826H.746C2.442 20.744 6.84 24 12 24Z",
        fill: "#0052B4"
      }
    )), /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "NL_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" }))));
  };
  var usaFlag = () => {
    return /* @__PURE__ */ React.createElement("svg", { width: 24, height: 24, fill: "none", viewBox: "0 0 24 24" }, /* @__PURE__ */ React.createElement("g", { clipPath: "url(#US_svg__a)" }, /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
        fill: "#F0F0F0"
      }
    ), /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M11.477 12H24a12.01 12.01 0 0 0-.413-3.13H11.478V12Zm0-6.262h10.761a12.064 12.064 0 0 0-2.769-3.13h-7.992v3.13ZM12 24c2.824 0 5.42-.976 7.47-2.609H4.53A11.948 11.948 0 0 0 12 24ZM1.761 18.26h20.477a11.93 11.93 0 0 0 1.348-3.13H.413c.3 1.116.758 2.167 1.348 3.13Z",
        fill: "#D80027"
      }
    ), /* @__PURE__ */ React.createElement(
      "path",
      {
        d: "M5.559 1.874h1.093l-1.017.739.389 1.196-1.018-.74-1.017.74.336-1.033c-.896.746-1.68 1.62-2.328 2.594h.35l-.647.47c-.1.168-.197.34-.29.513l.31.951-.578-.419C1 7.19.868 7.5.75 7.817l.34 1.048h1.258l-1.017.74.388 1.195-1.017-.739-.61.443C.033 10.994 0 11.494 0 12h12V0C9.63 0 7.42.688 5.559 1.874Zm.465 8.926-1.018-.739-1.017.739.389-1.196-1.017-.739h1.257l.388-1.195.389 1.195h1.257l-1.017.74.389 1.195Zm-.389-4.691.389 1.195-1.018-.739-1.017.74.389-1.196-1.017-.74h1.257l.388-1.195.389 1.196h1.257l-1.017.739Zm4.693 4.691-1.017-.739-1.017.739.388-1.196-1.017-.739h1.257l.389-1.195.388 1.195h1.258l-1.018.74.389 1.195Zm-.389-4.691.389 1.195-1.017-.739-1.017.74.388-1.196-1.017-.74h1.257l.389-1.195.388 1.196h1.258l-1.018.739Zm0-3.496.389 1.196-1.017-.74-1.017.74.388-1.196-1.017-.739h1.257L9.311.678l.388 1.196h1.258l-1.018.739Z",
        fill: "#0052B4"
      }
    )), /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "US_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" }))));
  };
  var frenchFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#FR_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M24 12c0-5.16-3.257-9.558-7.826-11.254v22.508C20.744 21.558 24 17.159 24 12Z",
          fill: "#D80027"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M0 12c0 5.16 3.257 9.559 7.826 11.254V.747C3.256 2.443 0 6.841 0 12.001Z",
          fill: "#0052B4"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "FR_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var germanFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#DE_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M.746 16.175C2.442 20.745 6.84 24 12 24c5.16 0 9.558-3.257 11.253-7.826L12 15.132.746 16.175Z",
          fill: "#FFDA44"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 0C6.84 0 2.442 3.258.746 7.828L12 8.87l11.253-1.043C21.558 3.257 17.16 0 12 0Z",
          fill: "#000"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M.746 7.826A11.974 11.974 0 0 0 0 12c0 1.467.264 2.873.746 4.174h22.508c.482-1.3.746-2.707.746-4.174 0-1.468-.264-2.874-.746-4.174H.746Z",
          fill: "#D80027"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "DE_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var italianFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#IT_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M24 12c0-5.16-3.257-9.56-7.826-11.255v22.507C20.744 21.557 24 17.159 24 11.999Z",
          fill: "#D80027"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M0 12c0 5.16 3.256 9.558 7.826 11.253V.746C3.256 2.442 0 6.84 0 12Z",
          fill: "#6DA544"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "IT_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var indianFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#IN_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 0C6.84 0 2.442 3.257.746 7.826h22.508C21.557 3.257 17.159 0 12 0Z",
          fill: "#FF9811"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c5.16 0 9.558-3.257 11.254-7.826H.746C2.443 20.743 6.841 24 12 24Z",
          fill: "#6DA544"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 14.609a2.609 2.609 0 1 0 0-5.218 2.609 2.609 0 0 0 0 5.218Z",
          fill: "#0052B4"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 13.565a1.565 1.565 0 1 0 0-3.13 1.565 1.565 0 0 0 0 3.13Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 8.87v1.043M12 14.087v1.044M15.13 12h-1.043M9.913 12H8.87M14.213 9.787l-.739.739M10.526 13.474l-.739.739M14.213 14.213l-.739-.739M10.526 10.526l-.739-.739",
          stroke: "#0052B4",
          strokeLinecap: "round",
          strokeWidth: "0.7"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "IN_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var egyptianFlag = () => {
    const id = `EG_svg__${++egyptianFlagCounter}`;
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: `url(#${id})` }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 0C6.84 0 2.442 3.257.746 7.826h22.508C21.557 3.257 17.159 0 12 0Z",
          fill: "#CE1126"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c5.16 0 9.558-3.257 11.254-7.826H.746C2.443 20.743 6.841 24 12 24Z",
          fill: "#000"
        }
      ), /* @__PURE__ */ React.createElement("g", { fill: "#C09300", stroke: "#8C6F00", strokeWidth: "0.12" }, /* @__PURE__ */ React.createElement("path", { d: "M11.52 8.32c.28-.3.68-.47 1.1-.47.48 0 .93.22 1.21.59l.35.45.8-.32c.23-.09.47.12.4.36l-.24.85 2.31-1.1c.28-.13.57.16.43.43-.7 1.39-1.84 2.38-3.34 2.86l-.55.18v2.26h-3.98v-2.26l-.55-.18c-1.5-.48-2.64-1.47-3.34-2.86-.14-.27.15-.56.43-.43l2.31 1.1-.24-.85c-.07-.24.17-.45.4-.36l.8.32.34-.45c.28-.37.72-.59 1.36-.12Z" }), /* @__PURE__ */ React.createElement("path", { d: "M10.52 10.2h2.96l-.49 1.16h-1.98l-.49-1.16Z" }), /* @__PURE__ */ React.createElement("path", { d: "M10.9 12.15h2.2v2.25h-2.2v-2.25Z" }), /* @__PURE__ */ React.createElement("path", { d: "M9.62 14.56h4.76v.74H9.62z" }))),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var brazilianFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#BR_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#6DA544"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 4.696 21.913 12 12 19.305 2.087 12 12 4.696Z",
          fill: "#FFDA44"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 16.174a4.174 4.174 0 1 0 0-8.348 4.174 4.174 0 0 0 0 8.348Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M9.913 11.74a7.02 7.02 0 0 0-2.086.315 4.173 4.173 0 0 0 7.59 2.34 7.034 7.034 0 0 0-5.504-2.655Zm6.183 1.06a4.174 4.174 0 0 0-7.932-2.447 8.607 8.607 0 0 1 7.932 2.447Z",
          fill: "#0052B4"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "BR_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var greekFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#GR_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 8.87h11.587a11.932 11.932 0 0 0-1.348-3.13H12v3.13ZM4.53 21.391h14.94a12.06 12.06 0 0 0 2.77-3.13H1.761a12.064 12.064 0 0 0 2.769 3.13ZM4.174 2.904a12.059 12.059 0 0 0-2.412 2.835h2.412V2.904ZM12 12V8.87H7.304V12h-3.13V8.87H.414A12.013 12.013 0 0 0 0 12c0 1.083.144 2.132.413 3.13h23.174A12.01 12.01 0 0 0 24 12H12Z",
          fill: "#338AF3"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 0c-1.666 0-3.253.34-4.695.954V5.74H12V2.61h7.47A11.949 11.949 0 0 0 12 0Z",
          fill: "#338AF3"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "GR_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var japaneseFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#JP_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 17.218a5.217 5.217 0 1 0 0-10.435 5.217 5.217 0 0 0 0 10.435Z",
          fill: "#D80027"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "JP_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var chineseFlag = () => {
    const id = `CN_svg__${++chineseFlagCounter}`;
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: `url(#${id})` }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#DE2910"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M0-1 .235-.324H.951L.38.118.588.809 0 .39l-.588.419.208-.691-.571-.442h.716L0-1Z",
          fill: "#FFDE00",
          transform: "translate(6.15 6.15) scale(2.45)"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M0-1 .235-.324H.951L.38.118.588.809 0 .39l-.588.419.208-.691-.571-.442h.716L0-1Z",
          fill: "#FFDE00",
          transform: "translate(10.45 3.85) rotate(24) scale(.78)"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M0-1 .235-.324H.951L.38.118.588.809 0 .39l-.588.419.208-.691-.571-.442h.716L0-1Z",
          fill: "#FFDE00",
          transform: "translate(12.65 5.9) rotate(47) scale(.78)"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M0-1 .235-.324H.951L.38.118.588.809 0 .39l-.588.419.208-.691-.571-.442h.716L0-1Z",
          fill: "#FFDE00",
          transform: "translate(12.6 8.85) rotate(24) scale(.78)"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M0-1 .235-.324H.951L.38.118.588.809 0 .39l-.588.419.208-.691-.571-.442h.716L0-1Z",
          fill: "#FFDE00",
          transform: "translate(10.35 10.9) rotate(47) scale(.78)"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var russianFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#RU_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M23.254 16.173c.482-1.3.746-2.706.746-4.173 0-1.468-.264-2.874-.746-4.174H.746A11.974 11.974 0 0 0 0 11.999c0 1.468.264 2.874.746 4.174L12 17.217l11.254-1.044Z",
          fill: "#0052B4"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c5.16 0 9.559-3.257 11.254-7.827H.747C2.443 20.743 6.841 24 12.001 24Z",
          fill: "#D80027"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "RU_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };
  var polishFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#PL_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement("path", { d: "M0 12h24v12H0z", fill: "#D80027" })),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "PL_svg__a" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          fill: "#fff",
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z"
        }
      )))
    );
  };
  var irishFlag = () => {
    return /* @__PURE__ */ React.createElement(
      "svg",
      {
        width: "24",
        height: "24",
        fill: "none",
        xmlns: "http://www.w3.org/2000/svg",
        viewBox: "0 0 24 24"
      },
      /* @__PURE__ */ React.createElement("g", { clipPath: "url(#IE_svg__a)" }, /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M12 24c6.627 0 12-5.373 12-12S18.627 0 12 0 0 5.373 0 12s5.373 12 12 12Z",
          fill: "#F0F0F0"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M24 12c0-5.16-3.257-9.558-7.826-11.254v22.508C20.744 21.558 24 17.159 24 12Z",
          fill: "#FF9811"
        }
      ), /* @__PURE__ */ React.createElement(
        "path",
        {
          d: "M0 12c0 5.16 3.257 9.559 7.826 11.254V.747C3.256 2.443 0 6.841 0 12.001Z",
          fill: "#6DA544"
        }
      )),
      /* @__PURE__ */ React.createElement("defs", null, /* @__PURE__ */ React.createElement("clipPath", { id: "IE_svg__a" }, /* @__PURE__ */ React.createElement("path", { fill: "#fff", d: "M0 0h24v24H0z" })))
    );
  };

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

  // ../nosabos/nosabos/src/utils/speechEvaluation.js
  var SPEECH_REASON_MESSAGES = {
    en: {
      "speech-quality": "Speak a bit louder and keep a steady pace.",
      "not-target-lang": (targetLabel) => `Try speaking in ${targetLabel}.`,
      "low-char-sim": "Match the wording more closely.",
      "low-word-f1": "Include the key content words.",
      "low-confidence": "Speak clearly and reduce background noise."
    },
    es: {
      "speech-quality": "Habla un poco m\xE1s fuerte y mant\xE9n un ritmo constante.",
      "not-target-lang": (targetLabel) => `Intenta hablar en ${targetLabel}.`,
      "low-char-sim": "Ac\xE9rcate m\xE1s al texto original.",
      "low-word-f1": "Incluye las palabras clave del contenido.",
      "low-confidence": "Pronuncia con claridad y reduce el ruido de fondo."
    },
    pt: {
      "speech-quality": "Fale um pouco mais alto e mantenha um ritmo constante.",
      "not-target-lang": (targetLabel) => `Tente falar em ${targetLabel}.`,
      "low-char-sim": "Aproxime-se mais do texto original.",
      "low-word-f1": "Inclua as palavras-chave do conteudo.",
      "low-confidence": "Pronuncie com clareza e reduza o ruido de fundo."
    },
    it: {
      "speech-quality": "Parla un po' pi\xF9 forte e mantieni un ritmo regolare.",
      "not-target-lang": (targetLabel) => `Prova a parlare in ${targetLabel}.`,
      "low-char-sim": "Avvicinati di pi\xF9 al testo originale.",
      "low-word-f1": "Includi le parole chiave del contenuto.",
      "low-confidence": "Pronuncia con chiarezza e riduci il rumore di fondo."
    },
    de: {
      "speech-quality": "Sprich etwas lauter und halte ein gleichm\xE4\xDFiges Tempo.",
      "not-target-lang": (targetLabel) => `Versuche, auf ${targetLabel} zu sprechen.`,
      "low-char-sim": "Bleib n\xE4her am urspr\xFCnglichen Text.",
      "low-word-f1": "Nimm die wichtigsten Inhaltsw\xF6rter auf.",
      "low-confidence": "Sprich deutlich und reduziere Hintergrundger\xE4usche."
    },
    hi: {
      "speech-quality": "\u0925\u094B\u0921\u093C\u093E \u091C\u093C\u094B\u0930 \u0938\u0947 \u0914\u0930 \u0938\u094D\u0925\u093F\u0930 \u0917\u0924\u093F \u092E\u0947\u0902 \u092C\u094B\u0932\u093F\u090F\u0964",
      "not-target-lang": (targetLabel) => `${targetLabel} \u092E\u0947\u0902 \u092C\u094B\u0932\u0928\u0947 \u0915\u0940 \u0915\u094B\u0936\u093F\u0936 \u0915\u0940\u091C\u093F\u090F\u0964`,
      "low-char-sim": "\u092E\u0942\u0932 \u0935\u093E\u0915\u094D\u092F \u0915\u0947 \u0936\u092C\u094D\u0926\u094B\u0902 \u0915\u0947 \u0914\u0930 \u0915\u0930\u0940\u092C \u092C\u094B\u0932\u093F\u090F\u0964",
      "low-word-f1": "\u092E\u0941\u0916\u094D\u092F \u0905\u0930\u094D\u0925 \u0935\u093E\u0932\u0947 \u0936\u092C\u094D\u0926 \u091C\u093C\u0930\u0942\u0930 \u0936\u093E\u092E\u093F\u0932 \u0915\u0940\u091C\u093F\u090F\u0964",
      "low-confidence": "\u0938\u094D\u092A\u0937\u094D\u091F \u092C\u094B\u0932\u093F\u090F \u0914\u0930 \u0906\u0938\u092A\u093E\u0938 \u0915\u093E \u0936\u094B\u0930 \u0915\u092E \u0915\u0940\u091C\u093F\u090F\u0964"
    },
    ar: {
      "speech-quality": "\u0627\u062A\u0643\u0644\u0645 \u0628\u0635\u0648\u062A \u0623\u0648\u0636\u062D \u0648\u062D\u0627\u0641\u0638 \u0639\u0644\u0649 \u0633\u0631\u0639\u0629 \u062B\u0627\u0628\u062A\u0629.",
      "not-target-lang": (targetLabel) => `\u062D\u0627\u0648\u0644 \u062A\u062A\u0643\u0644\u0645 \u0628\u0640 ${targetLabel}.`,
      "low-char-sim": "\u0642\u0631\u0651\u0628 \u0643\u0644\u0627\u0645\u0643 \u0623\u0643\u062A\u0631 \u0645\u0646 \u0627\u0644\u062C\u0645\u0644\u0629 \u0627\u0644\u0623\u0635\u0644\u064A\u0629.",
      "low-word-f1": "\u062D\u0627\u0648\u0644 \u062A\u062F\u062E\u0644 \u0627\u0644\u0643\u0644\u0645\u0627\u062A \u0627\u0644\u0623\u0633\u0627\u0633\u064A\u0629 \u0641\u064A \u0627\u0644\u0645\u062D\u062A\u0648\u0649.",
      "low-confidence": "\u0627\u0646\u0637\u0642 \u0628\u0648\u0636\u0648\u062D \u0648\u0642\u0644\u0644 \u0627\u0644\u0636\u0648\u0636\u0627\u0621 \u062D\u0648\u0627\u0644\u064A\u0643."
    },
    fr: {
      "speech-quality": "Parle un peu plus fort et garde un rythme regulier.",
      "not-target-lang": (targetLabel) => `Essaie de parler en ${targetLabel}.`,
      "low-char-sim": "Rapproche-toi davantage du texte original.",
      "low-word-f1": "Inclue les mots cles du contenu.",
      "low-confidence": "Prononce clairement et reduis le bruit de fond."
    },
    ja: {
      "speech-quality": "\u3082\u3046\u5C11\u3057\u5927\u304D\u306A\u58F0\u3067\u3001\u4E00\u5B9A\u306E\u30DA\u30FC\u30B9\u3067\u8A71\u3057\u3066\u307F\u307E\u3057\u3087\u3046\u3002",
      "not-target-lang": (targetLabel) => `${targetLabel}\u3067\u8A71\u3057\u3066\u307F\u307E\u3057\u3087\u3046\u3002`,
      "low-char-sim": "\u5143\u306E\u6587\u306B\u3082\u3063\u3068\u8FD1\u3065\u3051\u3066\u307F\u307E\u3057\u3087\u3046\u3002",
      "low-word-f1": "\u91CD\u8981\u306A\u5185\u5BB9\u8A9E\u3092\u5165\u308C\u3066\u307F\u307E\u3057\u3087\u3046\u3002",
      "low-confidence": "\u306F\u3063\u304D\u308A\u767A\u97F3\u3057\u3001\u5468\u56F2\u306E\u96D1\u97F3\u3092\u6E1B\u3089\u3057\u307E\u3057\u3087\u3046\u3002"
    },
    zh: {
      "speech-quality": "\u8BF7\u58F0\u97F3\u66F4\u6E05\u695A\u4E00\u4E9B\uFF0C\u5E76\u4FDD\u6301\u7A33\u5B9A\u8BED\u901F\u3002",
      "not-target-lang": (targetLabel) => `\u8BF7\u5C1D\u8BD5\u7528${targetLabel}\u8BF4\u3002`,
      "low-char-sim": "\u8BF7\u66F4\u63A5\u8FD1\u539F\u53E5\u5185\u5BB9\u3002",
      "low-word-f1": "\u8BF7\u5305\u542B\u5173\u952E\u8BCD\u3002",
      "low-confidence": "\u8BF7\u6E05\u695A\u53D1\u97F3\uFF0C\u5E76\u51CF\u5C11\u80CC\u666F\u566A\u97F3\u3002"
    }
  };
  function speechReasonTips(reasons = [], { uiLang = "en", targetLabel } = {}) {
    const lang = normalizeSupportLanguage(uiLang, DEFAULT_SUPPORT_LANGUAGE);
    const msgs = SPEECH_REASON_MESSAGES[lang];
    const tips = [];
    reasons.forEach((reason) => {
      const msg = msgs[reason];
      if (typeof msg === "function")
        tips.push(
          msg(
            targetLabel || (lang === "es" ? "el idioma objetivo" : lang === "pt" ? "o idioma alvo" : lang === "it" ? "la lingua obiettivo" : lang === "de" ? "die Zielsprache" : lang === "hi" ? "\u0932\u0915\u094D\u0937\u094D\u092F \u092D\u093E\u0937\u093E" : lang === "zh" ? "\u76EE\u6807\u8BED\u8A00" : lang === "fr" ? "la langue cible" : lang === "ja" ? "\u76EE\u6A19\u8A00\u8A9E" : lang === "ar" ? "\u0627\u0644\u0644\u063A\u0629 \u0627\u0644\u0647\u062F\u0641" : "the target language")
          )
        );
      else if (msg) tips.push(msg);
    });
    if (!tips.length) {
      tips.push(
        lang === "es" ? "Vuelve a intentarlo hablando con claridad." : lang === "pt" ? "Tente novamente falando com clareza." : lang === "it" ? "Riprova parlando chiaramente." : lang === "de" ? "Versuche es noch einmal und sprich deutlich." : lang === "hi" ? "\u0938\u094D\u092A\u0937\u094D\u091F \u092C\u094B\u0932\u0924\u0947 \u0939\u0941\u090F \u092B\u093F\u0930 \u0938\u0947 \u0915\u094B\u0936\u093F\u0936 \u0915\u0940\u091C\u093F\u090F\u0964" : lang === "zh" ? "\u8BF7\u6E05\u695A\u5730\u8BF4\uFF0C\u7136\u540E\u518D\u8BD5\u4E00\u6B21\u3002" : lang === "fr" ? "Reessaie en parlant clairement." : lang === "ja" ? "\u306F\u3063\u304D\u308A\u8A71\u3057\u3066\u3001\u3082\u3046\u4E00\u5EA6\u8A66\u3057\u3066\u307F\u307E\u3057\u3087\u3046\u3002" : lang === "ar" ? "\u062D\u0627\u0648\u0644 \u0645\u0631\u0629 \u062A\u0627\u0646\u064A\u0629 \u0648\u0627\u062A\u0643\u0644\u0645 \u0628\u0648\u0636\u0648\u062D." : "Try again, speaking clearly."
      );
    }
    return tips;
  }
  return __toCommonJS(stdin_exports);
})();

return{run(op,json){const p=JSON.parse(json);if(op!=='tips')throw Error(op);return JSON.stringify(OriginalStoryFeedback.speechReasonTips(p.reasons,{uiLang:p.language,targetLabel:p.targetLabel}))}}})()
