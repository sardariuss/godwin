import { Category, CategoryInfo, Polarization } from "./../../../declarations/godwin_backend/godwin_backend.did";

import AggregateDigest from "../base/AggregateDigest";
import CONSTANTS from "../../Constants";
import { polarizationToCursor, CursorInfo, toCursorInfo, toPolarizationInfo } from "../../utils";

import { useState, useEffect } from "react";

type Props = {
  aggregate: Map<Category, Polarization> | undefined,
  categories: Map<Category, CategoryInfo>,
  selected: boolean,
  setSelected: (selected: boolean) => void
};

const CategorizationAggregate = ({ aggregate, categories, selected, setSelected }: Props) => {

  const [cursorInfo, setCursorInfo] = useState<CursorInfo | undefined>(undefined);

  const refreshCursorInfo = async () => {
    if (aggregate !== undefined) {
      var winning_cursor = 0;
      var winning_dimension = "";
      aggregate.forEach((polarization, dimension) => {
        let cursor = polarizationToCursor(polarization);
        if (Math.abs(cursor) > Math.abs(winning_cursor)) {
          winning_cursor = cursor;
          winning_dimension = dimension;
        };
      });
      setCursorInfo(toCursorInfo(winning_cursor, toPolarizationInfo(categories.get(winning_dimension), CONSTANTS.CATEGORIZATION_INFO.center)));
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

export default CategorizationAggregate;
