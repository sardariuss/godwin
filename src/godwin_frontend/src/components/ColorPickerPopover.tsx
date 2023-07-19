import useClickOutside                          from "../utils/useClickOutside";

import React, { useCallback, useRef, useState } from "react";
import { HexColorPicker }                       from "react-colorful";

export const ColorPickerPopover = ({ color, onChange }) => {
  
  const popover = useRef();
  const [isOpen, toggle] = useState(false);

  const close = useCallback(() => toggle(false), []);
  useClickOutside(popover, close);

  return (
    <div className="picker">
      <div
        id={"picker"}
        className="swatch"
        style={{ backgroundColor: color }}
        onClick={() => toggle(true)}
      />

      {isOpen && (
        <div className="popover z-50" ref={popover}>
          <HexColorPicker color={color} onChange={onChange} />
        </div>
      )}
    </div>
  );
};