import CONSTANTS        from "../../Constants";
import { Interest }     from "./../../../declarations/godwin_sub/godwin_sub.did";

export enum InterestEnum {
  Up,
  Neutral,
  Down,
}

export type InterestInfo = {
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

