import React from "react";

type Props = {
  symbol: string | undefined;
  value: string | undefined;
  selected: boolean;
  setSelected: (selected: boolean) => void;
};

const AggregateDigest = ({ symbol, value, selected, setSelected }: Props) => {

	return (
    <button type="button" onClick={(e) => setSelected(!selected) } className={"flex flex-row group items-center hover:cursor-pointer text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-white" + (selected ? " font-bold text-gray-700 dark:text-white" : "")} >
      {/* truncate is used to force the text to be on a single line*/}
      <div className={`text-sm truncate`}>{ value !== undefined ? value : "n/a" } </div>
      <div className="text">{ symbol !== undefined ? symbol : "" }</div>
    </button>
	);
};

export default AggregateDigest;
