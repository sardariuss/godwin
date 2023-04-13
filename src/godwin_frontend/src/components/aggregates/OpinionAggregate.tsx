import { Polarization } from "./../../../declarations/godwin_backend/godwin_backend.did";

import AggregateDigest from "../base/AggregateDigest";
import CONSTANTS from "../../Constants";
import { polarizationToCursor, toCursorInfo, CursorInfo } from "../../utils";

import { useState, useEffect } from "react";

type Props = {
  aggregate: Polarization | undefined,
  selected: boolean,
  setSelected: (selected: boolean) => void
};

const OpinionAggregate = ({ aggregate, selected, setSelected }: Props) => {

  const [cursorInfo, setCursorInfo] = useState<CursorInfo | undefined>(undefined);

  const refreshCursorInfo = async () => {
    if (aggregate !== undefined) {
      setCursorInfo(toCursorInfo(polarizationToCursor(aggregate), CONSTANTS.OPINION_INFO));
    } else {
      setCursorInfo(undefined);
    }
  };

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

export default OpinionAggregate;
