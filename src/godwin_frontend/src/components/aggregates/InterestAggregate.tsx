import { Appeal } from "./../../../declarations/godwin_backend/godwin_backend.did";

import AggregateDigest from "../base/AggregateDigest";
import CONSTANTS from "../../Constants";

type Props = {
  aggregate: Appeal | undefined,
  selected: boolean,
  setSelected: (selected: boolean) => void
};

const InterestAggregate = ({ aggregate, selected, setSelected }: Props) => {

	return (
    <AggregateDigest
      symbol={ aggregate !== undefined ? aggregate.ups > aggregate.downs ? CONSTANTS.INTEREST_INFO.right.symbol : CONSTANTS.INTEREST_INFO.left.symbol : undefined }
      value={ aggregate !== undefined ? aggregate.score + " points" : undefined }
      selected={ selected }
      setSelected={ setSelected }
    />
	);
};

export default InterestAggregate;
