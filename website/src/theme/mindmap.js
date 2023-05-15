import React, { useEffect, useRef } from "react";
import { Transformer } from 'markmap-lib';
import * as markmap from 'markmap-view';

const WIDTH = "80%";
const HEIGHT = "30vh";

const transformer = new Transformer();
const { Markmap, loadCSS, loadJS } = markmap;

const mindmap = ({ markdown, config }) => {
  if (!markdown) return null;
  const ref = useRef()

  useEffect(() => {
    try {
      const { root, features } = transformer.transform(markdown.trim());
      const { styles, scripts } = transformer.getUsedAssets(features);

      // 1. load assets
      if (styles) loadCSS(styles);
      if (scripts) loadJS(scripts, { getMarkmap: () => markmap });

      // 2. create markmap
      var el = Markmap.create(ref.current, { autoFit: false }, root);
    } catch (e) {
      console.error(e);
    }
    return () => {
      el.styleNode.interrupt();
      el.g.interrupt();
      el.svg.interrupt();
    };
  }, [markdown])

  return <svg ref={ref} width={WIDTH} height={HEIGHT}></svg>;
}

export default mindmap;
