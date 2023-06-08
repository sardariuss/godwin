import CONSTANTS        from "../../Constants";
import { toCursorInfo } from "../../utils";
import { Interest }     from "./../../../declarations/godwin_backend/godwin_backend.did";

export enum InterestEnum {
  Up,
  Neutral,
  Down,
}

type InterestInfo = {
  name: string;
  symbol: string;
}

export const interestToEnum = (interest: Interest) : InterestEnum => {
  if (interest['UP'] !== undefined)      return InterestEnum.Up;
  if (interest['DOWN'] !== undefined)    return InterestEnum.Down;
  throw new Error('Invalid interest');
}

export const getInterestInfo = (interest: InterestEnum) : InterestInfo => {
  if (interest === InterestEnum.Up)      { return CONSTANTS.INTEREST_INFO.up; }
  if (interest === InterestEnum.Neutral) { return CONSTANTS.INTEREST_INFO.neutral; }
  if (interest === InterestEnum.Down)    { return CONSTANTS.INTEREST_INFO.down; }
  throw new Error('Invalid interestEnum');
}

export const enumToInterest = (interestEnum: InterestEnum) : Interest => {
  if (interestEnum === InterestEnum.Up)      return { 'UP' : null };
  if (interestEnum === InterestEnum.Down)    return { 'DOWN' : null };
  throw new Error('Invalid interestEnum');
}

// @todo: temporary
export type CursorInfo = {
  value: number;
  name: string;
  symbol: string;
  colors: {
    left: string;
    right: string;
  };
};

// @todo: temporary
export const interestToCursorInfo = (interest: InterestEnum | null) : CursorInfo => {
  if (interest === InterestEnum.Up) {
    return toCursorInfo(1.0, CONSTANTS.INTEREST_INFO);
  } if (interest === InterestEnum.Down) {
    return toCursorInfo(-1.0, CONSTANTS.INTEREST_INFO);
  }
  return toCursorInfo(0.0, CONSTANTS.INTEREST_INFO);
}
