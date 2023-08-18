import AggregateDigest                          from "../base/AggregateDigest";
import CONSTANTS                                from "../../Constants";
import { polarizationToCursor, CursorInfo,  
   getStrongestCategoryCursorInfo }             from "../../utils";
import { Category, CategoryInfo, Polarization } from "./../../../declarations/godwin_sub/godwin_sub.did";

import React, { useState, useEffect }           from "react";

type Props = {
  aggregate: Map<Category, Polarization> | undefined,
  categories: Map<Category, CategoryInfo>,
  selected: boolean,
  setSelected: (selected: boolean) => void
};

const CategorizationAggregateDigest = ({ aggregate, categories, selected, setSelected }: Props) => {

  const [cursorInfo, setCursorInfo] = useState<CursorInfo | undefined>(undefined);

  const refreshCursorInfo = async () => {
    if (aggregate !== undefined) {
      let cursor_array : [string, number][] = [];
      aggregate.forEach((polarization, dimension) => {
        cursor_array.push([dimension, polarizationToCursor(polarization)]);
      });
      setCursorInfo(getStrongestCategoryCursorInfo(cursor_array, categories));
    } else {
      setCursorInfo(undefined);
    }
  }

  useEffect(() => {
    refreshCursorInfo();
  }, [aggregate]);

	return (
    <AggregateDigest 
      symbol={ cursorInfo !== undefined ? cursorInfo.symbol : undefined }
      value={ cursorInfo !== undefined ? cursorInfo.value.toFixed(CONSTANTS.CURSOR_DECIMALS) : undefined }
      selected={ selected }
      setSelected={ setSelected }
    />
	);
};

export default CategorizationAggregateDigest;
