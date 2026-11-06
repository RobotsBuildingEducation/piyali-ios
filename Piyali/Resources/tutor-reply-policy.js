// Original Tutor phrase filtering, overlap order and repeated-token construction. UI and I/O stay native.
(function(){const React={createElement:(_,props,...children)=>({text:children.join(''),token:props['data-token'],root:props['data-token'].split('_')[0]})};const COLORS = [
  "#91E0FF",
  "#A0EBAF",
  "#FFD48A",
  "#C6B7FF",
  "#FF9FB1",
  "#B0F0FF"
];
function normalizePairText(text) {
  return String(text || "").normalize("NFKC").toLowerCase().replace(/\s+/g, " ").trim();
}
function textIncludesPair(haystack, needle) {
  const normalizedHaystack = normalizePairText(haystack);
  const normalizedNeedle = normalizePairText(needle);
  return !!normalizedNeedle && normalizedHaystack.includes(normalizedNeedle);
}
function filterPairsForPrimaryText(pairs, primaryText) {
  if (!Array.isArray(pairs)) return [];
  return pairs.filter((pair) => textIncludesPair(primaryText, pair?.lhs));
}
function wrapFirst(text, phrase, tokenId) {
  if (!text || !phrase) return [text];
  const idx = text.toLowerCase().indexOf(String(phrase).toLowerCase());
  if (idx < 0) return [text];
  const before = text.slice(0, idx);
  const mid = text.slice(idx, idx + phrase.length);
  const after = text.slice(idx + phrase.length);
  return [
    before,
    /* @__PURE__ */ React.createElement(
      "span",
      {
        key: `${tokenId}-${idx}`,
        "data-token": tokenId,
        style: {
          display: "inline",
          boxShadow: "inset 0 -2px transparent",
          unicodeBidi: "isolate"
        }
      },
      mid
    ),
    ...wrapFirst(after, phrase, tokenId + "_cont")
  ];
}
function buildAlignedNodes(text, pairs, side) {
  if (!pairs?.length || !text) return [text];
  const sorted = [...pairs].sort(
    (a, b) => (b?.[side]?.length || 0) - (a?.[side]?.length || 0)
  );
  let nodes = [text];
  sorted.forEach((pair, i) => {
    const phrase = pair?.[side];
    if (!phrase) return;
    const tokenId = `tok_${i}`;
    const next = [];
    nodes.forEach((node) => {
      if (typeof node === "string")
        next.push(...wrapFirst(node, phrase, tokenId));
      else next.push(node);
    });
    nodes = next;
  });
  return nodes;
}

return {run:function(input){const p=JSON.parse(input),pairs=filterPairsForPrimaryText(p.pairs,p.primaryText);return JSON.stringify({pairs,colors:COLORS,primary:buildAlignedNodes(p.primaryText,pairs,'lhs'),secondary:buildAlignedNodes(p.secondaryText,pairs,'rhs')})}}})()