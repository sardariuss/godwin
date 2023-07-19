import React, { useCallback, useRef, useState } from "react";
import EmojiPicker, { EmojiStyle }              from 'emoji-picker-react';
import { EmojiClickData }                       from "emoji-picker-react";

import useClickOutside                          from "../utils/useClickOutside";

export const EmojiPickerPopover = ({ emoji, onChange }) => {
  const popover = useRef();
  const [isOpen, toggle] = useState(false);

  const close = useCallback(() => toggle(false), []);
  useClickOutside(popover, close);

  return (
    <div className="flex flex-col picker w-10 items-center hover:cursor-pointer" onClick={() => toggle(true)}>
      <div id={"picker bg-red-300 text-3xl text-center"}>
        {emoji}
      </div>

      {isOpen && (
        <div className="popover z-50" ref={popover}>
          <EmojiPicker
            previewConfig={{defaultCaption: "", defaultEmoji: emoji}}
            onEmojiClick={(emojiData: EmojiClickData) => { onChange(emojiData.emoji); }}
            emojiStyle={EmojiStyle.NATIVE}
            lazyLoadEmojis={true}
          />
        </div>
      )}
    </div>
  );
};