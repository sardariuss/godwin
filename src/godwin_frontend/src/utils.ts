import { AccessControlError, VoteStatus, PutBallotError, VoteKind as VoteKindIdl, PayinError, OpenQuestionError, 
  Status, Polarization, CategorySide, CategoryInfo, QuestionOrderBy, Direction, SchedulerParameters__1, Duration,
  KindRevealableBallot, OpinionAnswer, CursorArray, VoteData, KindAnswer, KindVote,
  InterestVote, OpinionVote, CategorizationVote } from "./../declarations/godwin_sub/godwin_sub.did";
import { Category, CreateSubGodwinError, Result_1 } from "../declarations/godwin_master/godwin_master.did";
import CONSTANTS from "./Constants";
import { fromNullable } from "@dfinity/utils";
import { InterestEnum, interestToEnum, enumToInterest } from "./components/interest/InterestTypes";

import Color from 'colorjs.io';

export enum ChartTypeEnum {
  Bar,
  Scatter,
}

export type PolarizationInfo = {
  left: CategorySide;
  center: CategorySide;
  right: CategorySide;
};

export type CursorInfo = {
  value: number;
  name: string;
  symbol: string;
  colors: {
    left: string;
    right: string;
  };
};

export enum VoteKind {
  INTEREST,
  OPINION,
  CATEGORIZATION,
};

export const VoteKinds = [
  VoteKind.INTEREST,
  VoteKind.OPINION,
  VoteKind.CATEGORIZATION,
];

export const voteKindFromCandidVariant = (idl: VoteKindIdl) => {
  if (idl['INTEREST'] !== undefined) return VoteKind.INTEREST;
  if (idl['OPINION'] !== undefined) return VoteKind.OPINION;
  if (idl['CATEGORIZATION'] !== undefined) return VoteKind.CATEGORIZATION;
  throw new Error('Invalid voteKind');
};

export const voteKindToString = (voteKind: VoteKind) => {
  if (voteKind === VoteKind.INTEREST) return 'Interest';
  if (voteKind === VoteKind.OPINION) return 'Opinion';
  if (voteKind === VoteKind.CATEGORIZATION) return 'Categorization';
  throw new Error('Invalid voteKind');
};

export const voteKindToCandidVariant = (voteKind: VoteKind) => {
  if (voteKind === VoteKind.INTEREST) return { 'INTEREST' : null };
  if (voteKind === VoteKind.OPINION) return { 'OPINION' : null };
  if (voteKind === VoteKind.CATEGORIZATION) return { 'CATEGORIZATION' : null };
  throw new Error('Invalid voteKind');
};

export const orderByToString = (orderBy: QuestionOrderBy) => {
  if (orderBy['AUTHOR'] !== undefined) return 'Author';
  if (orderBy['DATE'] !== undefined) return 'Date';
  if (orderBy['TEXT'] !== undefined) return 'Text';
  if (orderBy['HOTNESS'] !== undefined) return 'Interest score';
  if (orderBy['STATUS'] !== undefined) return 'Status: ' + statusToString(orderBy['STATUS']);
  if (orderBy['OPINION_VOTE'] !== undefined) return 'Opinion vote';
  throw new Error('Invalid orderBy');
};

export const directionToString = (direction: Direction) => {
  if (direction['FWD'] !== undefined) return 'Forward';
  if (direction['BWD'] !== undefined) return 'Backward';
  throw new Error('Invalid direction');
};

export const statusToString = (status: Status) => {
  if (status['CANDIDATE'] !== undefined            ) return 'Candidate';
  if (status['OPEN'] !== undefined                 ) return 'Open';
  if (status['CLOSED'] !== undefined               ) return 'Closed';
  if (status['REJECTED']['TIMED_OUT'] !== undefined) return 'Timed out';
  if (status['REJECTED']['CENSORED'] !== undefined ) return 'Censored';
  throw new Error('Invalid status');
};

export const statusEnumToString = (status: StatusEnum) => {
  if (status === StatusEnum.CANDIDATE) return 'Candidate';
  if (status === StatusEnum.OPEN) return 'Open';
  if (status === StatusEnum.CLOSED) return 'Closed';
  if (status === StatusEnum.TIMED_OUT) return 'Timed out';
  if (status === StatusEnum.CENSORED) return 'Censored';
  throw new Error('Invalid status');
};

export enum StatusEnum {
  CANDIDATE,
  OPEN,
  CLOSED,
  TIMED_OUT,
  CENSORED
};

export const statusToEnum = (status: Status) => {
  if (status['CANDIDATE'] !== undefined            ) return StatusEnum.CANDIDATE;
  if (status['OPEN'] !== undefined                 ) return StatusEnum.OPEN;
  if (status['CLOSED'] !== undefined               ) return StatusEnum.CLOSED;
  if (status['REJECTED']['TIMED_OUT'] !== undefined) return StatusEnum.TIMED_OUT;
  if (status['REJECTED']['CENSORED'] !== undefined ) return StatusEnum.CENSORED;
  throw new Error('Invalid status');
};

// @todo: have a payin error instead of all at the root
export const openQuestionErrorToString = (error: OpenQuestionError) => {
  if (error['TextTooLong']          !== undefined) return 'TextTooLong';
  if (error['PrincipalIsAnonymous'] !== undefined) return 'PrincipalIsAnonymous';
  if (error['GenericError']           !== undefined) return 'GenericError: message=' + error['GenericError']['message'] + ', error_code=' + Number(error['GenericError']['error_code']).toString();
  if (error['TemporarilyUnavailable'] !== undefined) return 'TemporarilyUnavailable';
  if (error['NotAllowed']             !== undefined) return 'NotAllowed';
  if (error['BadBurn']                !== undefined) return 'BadBurn: min_burn_amount=' + Number(error['BadBurn']['min_burn_amount']).toString();
  if (error['Duplicate']              !== undefined) return 'Duplicate: duplicate_of=' + Number(error['Duplicate']['duplicate_of']).toString();
  if (error['BadFee']                 !== undefined) return 'BadFee: expected_fee=' + Number(error['BadFee']['expected_fee']).toString();
  if (error['CreatedInFuture']        !== undefined) return 'CreatedInFuture: ledger_time=' + Number(error['CreatedInFuture']['ledger_time']).toString();
  if (error['TooOld']                 !== undefined) return 'TooOld';
  if (error['CanisterCallError']      !== undefined) return 'CanisterCallError';
  if (error['InsufficientFunds']      !== undefined) return 'InsufficientFunds: balance=' + Number(error['InsufficientFunds']['balance']).toString();
  throw new Error('Invalid PutBallotError');
};

export const putBallotErrorToString = (error: PutBallotError) => {
  if (error['ChangeBallotNotAllowed']!== undefined) return 'ChangeBallotNotAllowed';
  if (error['NoSubacountLinked']     !== undefined) return 'NoSubacountLinked';
  if (error['InvalidBallot']         !== undefined) return 'InvalidBallot';
  if (error['VoteClosed']            !== undefined) return 'VoteClosed';
  if (error['VoteNotFound']          !== undefined) return 'VoteNotFound';
  if (error['PrincipalIsAnonymous']  !== undefined) return 'PrincipalIsAnonymous';
  if (error['VoteLocked']            !== undefined) return 'VoteLocked';
  if (error['PayinError']            !== undefined) return 'PayinError: ' + payInErrorToString(error['PayinError']);
  throw new Error('Invalid PutBallotError');
};

export const payInErrorToString = (error: PayinError) => {
  if (error['GenericError']           !== undefined) return 'GenericError: message=' + error['GenericError']['message'] + ', error_code=' + Number(error['GenericError']['error_code']).toString();
  if (error['TemporarilyUnavailable'] !== undefined) return 'TemporarilyUnavailable';
  if (error['NotAllowed']             !== undefined) return 'NotAllowed';
  if (error['BadBurn']                !== undefined) return 'BadBurn: min_burn_amount=' + Number(error['BadBurn']['min_burn_amount']).toString();
  if (error['Duplicate']              !== undefined) return 'Duplicate: duplicate_of=' + Number(error['Duplicate']['duplicate_of']).toString();
  if (error['BadFee']                 !== undefined) return 'BadFee: expected_fee=' + Number(error['BadFee']['expected_fee']).toString();
  if (error['CreatedInFuture']        !== undefined) return 'CreatedInFuture: ledger_time=' + Number(error['CreatedInFuture']['ledger_time']).toString();
  if (error['TooOld']                 !== undefined) return 'TooOld';
  if (error['CanisterCallError']      !== undefined) return 'CanisterCallError';
  if (error['InsufficientFunds']      !== undefined) return 'InsufficientFunds: balance=' + Number(error['InsufficientFunds']['balance']).toString();
  throw new Error('Invalid PayinError');
};

export const toMap = (arr: Array<any>) => {
  let map = new Map<any, any>();
  arr.forEach((elem) => {
    map.set(elem[0], elem[1]);
  });
  return map;
};

export const polarizationToCursor = (polarization: Polarization) : number => {
  return (polarization.right - polarization.left) / (polarization.left + polarization.center + polarization.right);
};

export const getNormalizedPolarization = (polarization: Polarization) : Polarization => {
  let sum = polarization.left + polarization.center + polarization.right;
  if (sum === 0.0) {
    return {
      left: 0.0,
      center: 0.0,
      right: 0.0,
    }
  }
  return {
    left: polarization.left / sum,
    center: polarization.center / sum,
    right: polarization.right / sum,
  };
};

export const toPolarization = (cursor: number) : Polarization => {
  if (Math.abs(cursor) > 1.0) {
    throw new Error('Invalid cursor');
  }
  if (cursor >= 0.0) {
    return {
      left   : 0,
      center : 1.0 - cursor,
      right  : cursor,
    };
  } else {
    return {
      left   : -cursor,
      center : 1.0 + cursor,
      right  : 0,
    };
  };
}

export const mul = (polarization: Polarization, coef: number) : Polarization => {
  if (coef >= 0.0){
    return {
      left   : polarization.left * coef,
      center : polarization.center * coef,
      right  : polarization.right * coef,
    };
  } else {
    return {
      left   : polarization.right * -coef,
      center : polarization.center * -coef,
      right  : polarization.left * -coef,
    };
  }
};

export const addPolarization = (polarization1: Polarization, polarization2: Polarization) : Polarization => {
  return {
    left   : polarization1.left + polarization2.left,
    center : polarization1.center + polarization2.center,
    right  : polarization1.right + polarization2.right,
  };
};

export const toCursorInfo = (cursor: number, polarizationInfo: PolarizationInfo, alpha : number = 1.0) : CursorInfo => {
  const white = new Color("#dddddd");
  // Invert the color ranges to get the correct gradient
  const leftRange = white.range(polarizationInfo.right.color, { space: "lch", outputSpace: "lch"});
  const rightRange = white.range(polarizationInfo.left.color, { space: "lch", outputSpace: "lch"});

  const left = new Color(leftRange(cursor > 0 ? cursor : 0).toString()).to("srgb");
  const right = new Color(rightRange(cursor < 0 ? -cursor : 0).toString()).to("srgb");

  const colors = {
    left : new Color('srgb', left.coords, alpha).toString({format: "hex"}),
    right: new Color('srgb', right.coords, alpha).toString({format: "hex"}),
  };

  if (cursor < (-1 * CONSTANTS.CURSOR_SIDE_THRESHOLD)) {
    return { name: polarizationInfo.left.name, symbol: polarizationInfo.left.symbol, value: cursor, colors };
  } else if (cursor > CONSTANTS.CURSOR_SIDE_THRESHOLD) {
    return { name: polarizationInfo.right.name, symbol: polarizationInfo.right.symbol, value: cursor, colors };
  } else {
    return { name: polarizationInfo.center.name, symbol: polarizationInfo.center.symbol, value: cursor, colors };
  }
}

export const toOptCursorInfo = (cursor: number | undefined, polarizationInfo: PolarizationInfo) : CursorInfo | undefined => {
  if (cursor !== undefined){
    return toCursorInfo(cursor, polarizationInfo);
  }
  return undefined;
}

export enum VoteView {
  VOTE,
  LAST_BALLOT,
  BALLOT_HISTORY
};

export const toPolarizationInfo = (category_info: CategoryInfo, center: CategorySide) : PolarizationInfo => {
  return {
    left: category_info.left,
    center: center,
    right: category_info.right,
  };
}

// @todo: return the ranges instead ?
export const cursorToColor = (cursor: number, polarizationInfo: PolarizationInfo, alpha : number = 1.0) : string => {
  
  const white = new Color("#dddddd");
  const leftColorRange = white.range(polarizationInfo.left.color, { space: "lch", outputSpace: "lch"});
  const rightColorRange = white.range(polarizationInfo.right.color, { space: "lch", outputSpace: "lch"});

  if (cursor < 0.0){
    const left = new Color(leftColorRange(-cursor).toString()).to("srgb");
    return new Color('srgb', left.coords, alpha).toString({format: "hex"});
  } else {
    const right = new Color(rightColorRange(cursor).toString()).to("srgb");
    return new Color('srgb', right.coords, alpha).toString({format: "hex"});
  }
}

export type PolarizationColorRanges = {
  left: any,
  center: Color,
  right: any
};

export const polarizationToColorRange = (polarizationInfo: PolarizationInfo) : PolarizationColorRanges => {
  const white = new Color("#dddddd");
  // Invert the color ranges to get the correct gradient
  let leftColorRange = white.range(polarizationInfo.left.color, { space: "lch", outputSpace: "lch"});
  const rightColorRange = white.range(polarizationInfo.right.color, { space: "lch", outputSpace: "lch"});


  return {
    left: leftColorRange,
    center: white,
    right: rightColorRange,
  };
};

export interface ScanLimitResult<T> {
  'keys' : Array<T>,
  'next' : [] | [T],
};

export type ScanResults<T> = {
  ids: T[],
  next : T | undefined,
}

export const fromScanLimitResult = <T,>(query_result: ScanLimitResult<T>) : ScanResults<T> => {
  let ids = Array.from(query_result.keys);
  let next = fromNullable(query_result.next);
  return { ids, next };
}

export const convertScanResults = <T1, T2, >(scan_results: ScanResults<T1>, convert: (T1) => T2) : ScanResults<T2> => {
  let ids = scan_results.ids.map(convert);
  let next = scan_results.next === undefined ? undefined : convert(scan_results.next);
  return { ids, next };
}

export const getStrongestCategory = (ballot: Map<Category, number>) : [Category, number] => {
  var greatest_cursor = 0;
  var winning_category : Category = ballot.keys().next().value;
  ballot.forEach((cursor, category) => {
    if (Math.abs(cursor) > Math.abs(greatest_cursor)) {
      greatest_cursor = cursor;
      winning_category = category;
    };
  });
  return [winning_category, greatest_cursor];
};

export const getStrongestCategoryCursorInfo = (ballot: Map<Category, number>, categories: Map<Category, CategoryInfo>) : CursorInfo => {
  const [winning_category, greatest_cursor] = getStrongestCategory(ballot);
  return toCursorInfo(greatest_cursor, toPolarizationInfo(categories.get(winning_category), CONSTANTS.CATEGORIZATION_INFO.center));
};

export const getOptStrongestCategory = (categorization: CursorArray | undefined, categories: Map<Category, CategoryInfo>) : CursorInfo | undefined => {
  if (categorization !== undefined){
    return getStrongestCategoryCursorInfo(toMap(categorization), categories);
  }
  return undefined;
}

export const getStatusDuration = (status: Status, parameters: SchedulerParameters__1) : Duration | undefined =>  {
  if (status['CANDIDATE'] !== undefined) return parameters.candidate_status_duration;
  if (status['OPEN'] !== undefined     ) return parameters.open_status_duration;
  if (status['CLOSED'] !== undefined   ) return undefined;
  if (status['REJECTED'] !== undefined ) return parameters.rejected_status_duration;
  throw new Error('Invalid status');
}

export const durationToNanoSeconds = (duration: Duration) : bigint => {
  if (duration['YEARS'] !== undefined)  { return BigInt(duration['YEARS'])   * BigInt(365 * 24 * 60 * 60 * 1_000_000_000); };
  if (duration['DAYS'] !== undefined)   { return BigInt(duration['DAYS'])    * BigInt(      24 * 60 * 60 * 1_000_000_000); };
  if (duration['HOURS'] !== undefined)  { return BigInt(duration['HOURS'])   * BigInt(           60 * 60 * 1_000_000_000); };
  if (duration['MINUTES'] !== undefined){ return BigInt(duration['MINUTES']) * BigInt(                60 * 1_000_000_000); };
  if (duration['SECONDS'] !== undefined){ return BigInt(duration['SECONDS']) * BigInt(                     1_000_000_000); };
  if (duration['NS'] !== undefined)     { return BigInt(duration['NS']);                                                   };
  throw new Error('Invalid duration');
}

export enum VoteStatusEnum {
  OPEN,
  LOCKED,
  CLOSED,
}

export const voteStatusToEnum = (status: VoteStatus) : VoteStatusEnum => {
  if (status['OPEN']   !== undefined) return VoteStatusEnum.OPEN;
  if (status['LOCKED'] !== undefined) return VoteStatusEnum.LOCKED;
  if (status['CLOSED'] !== undefined) return VoteStatusEnum.CLOSED;
  throw new Error('Invalid vote status');
}

export const durationToString = (duration: Duration) : string => {
  if (duration['YEARS']   !== undefined) { return Number(duration['YEARS']).toString()   + ' years';   };
  if (duration['DAYS']    !== undefined) { return Number(duration['DAYS']).toString()    + ' days';    };
  if (duration['HOURS']   !== undefined) { return Number(duration['HOURS']).toString()   + ' hours';   };
  if (duration['MINUTES'] !== undefined) { return Number(duration['MINUTES']).toString() + ' minutes'; };
  if (duration['SECONDS'] !== undefined) { return Number(duration['SECONDS']).toString() + ' seconds'; };
  if (duration['NS']      !== undefined) { return Number(duration['NS']).toString()      + ' ns';      };
  throw new Error('Invalid duration');
}

export const durationToShortString = (duration: Duration) : string => {
  if (duration['YEARS']   !== undefined) { return Number(duration['YEARS']).toString()   + 'y';   };
  if (duration['DAYS']    !== undefined) { return Number(duration['DAYS']).toString()    + 'd';    };
  if (duration['HOURS']   !== undefined) { return Number(duration['HOURS']).toString()   + 'h';   };
  if (duration['MINUTES'] !== undefined) { return Number(duration['MINUTES']).toString() + 'm'; };
  if (duration['SECONDS'] !== undefined) { return Number(duration['SECONDS']).toString() + 's'; };
  if (duration['NS']      !== undefined) { return Number(duration['NS']).toString()      + 'ns';      };
  throw new Error('Invalid duration');
}

export const createSubGodwinErrorToString = (error: CreateSubGodwinError) : string => {
  if (error['DurationTooShort']           !== undefined) return 'Minimum duration is ' + durationToString(error['DurationTooShort']['minimum_duration']);
  if (error['DurationTooLong']            !== undefined) return 'Maximum duration is ' + durationToString(error['DurationTooLong']['maximum_duration']);
  if (error['MinimumInterestScoreTooLow'] !== undefined) return 'Minimum cannot be lower than ' + Number(error['MinimumInterestScoreTooLow']['minimum']).toString();
  if (error['CategoryDuplicate']          !== undefined) return 'Cannot have duplicate categories';
  if (error['CharacterLimitTooLong']      !== undefined) return 'Maximum limit is ' + Number(error['CharacterLimitTooLong']['maximum']).toString();
  if (error['IdentifierTooLong']          !== undefined) return 'Maximum identifier length is ' + Number(error['IdentifierTooLong']['max_length']).toString();
  if (error['IdentifierTooShort']         !== undefined) return 'Minimum identifier length is ' + Number(error['IdentifierTooShort']['min_length']).toString();
  if (error['IdentifierAlreadyTaken']     !== undefined) return 'Identifier is already taken';
  if (error['InvalidIdentifier']          !== undefined) return 'Invalid identifier';
  if (error['NoCategories']               !== undefined) return 'Cannot create a sub without categories';
  if (error['NameTooShort']               !== undefined) return 'Minimum name length is ' + Number(error['NameTooShort']['min_length']).toString();
  if (error['NameTooLong']                !== undefined) return 'Maximum name length is ' + Number(error['NameTooShort']['max_length']).toString();
  // From transfer error
  if (error['GenericError']               !== undefined) return 'GenericError';
  if (error['TemporarilyUnavailable']     !== undefined) return 'TemporarilyUnavailable'
  if (error['BadBurn']                    !== undefined) return 'BadBurn';
  if (error['Duplicate']                  !== undefined) return 'Duplicate';
  if (error['BadFee']                     !== undefined) return 'BadFee';
  if (error['CreatedInFuture']            !== undefined) return 'CreatedInFuture';
  if (error['TooOld']                     !== undefined) return 'TooOld'
  if (error['InsufficientFunds']          !== undefined) return 'InsufficientFunds';
  throw new Error('Invalid CreateSubGodwinError');
}

export const createSubResultToError = (result: Result_1) : string | undefined => {
  if (result['ok'] !== undefined){
    return undefined;
  } else if (result['err'] !== undefined){
    return createSubGodwinErrorToString(result['err']);
  } else {
    throw new Error("Invalid createSubGodwin result");
  }
}

export const accessControlErrorToString = (error: AccessControlError) : string => {
  if (error['AccessDenied'] !== undefined){
    let required_role = error['AccessDenied'].required_role;
    if (required_role['ADMIN'] !== undefined){ return "Access denied: ADMIN required"; }
    if (required_role['SUB'] !== undefined){ return "Access denied: SUB required"; }
  }
  throw new Error("Invalid access control error");
}

type RevealableAnswer<T> = { 'REVEALED' : T } | { 'HIDDEN' : null };

export const revealAnswer = <T>(answer: RevealableAnswer<T>) : T | undefined => {
  if (answer['REVEALED'] !== undefined){
    return answer['REVEALED'];
  } else if (answer['HIDDEN'] !== undefined){
    return undefined;
  } else {
    throw new Error("Invalid revealable answer");
  }
}

export type RevealableBallot<T> = {
  can_change : boolean,
  date       : bigint,
  answer     : T | undefined,
  vote_id    : bigint,
};

export const unwrapRevealedBallot = <T1, T2>(vote_kind_str: string, revealable_ballot: KindRevealableBallot, conversion: (T1) => (T2)) : RevealableBallot<T2> => {
  if (revealable_ballot[vote_kind_str] !== undefined){
    let b = revealable_ballot[vote_kind_str];
    let answer = revealAnswer(b.answer);
    return { can_change: b.can_change, date: b.date, answer: answer === undefined ? undefined : conversion(answer), vote_id: b.vote_id };
  }
  throw new Error("Invalid revealable ballot");
}

export const unwrapRevealedInterestBallot = (revealable_ballot: KindRevealableBallot) : RevealableBallot<InterestEnum> => {
  return unwrapRevealedBallot('INTEREST', revealable_ballot, interestToEnum);
}

export const unwrapRevealedOpinionBallot = (revealable_ballot: KindRevealableBallot) : RevealableBallot<OpinionAnswer> => {
  return unwrapRevealedBallot('OPINION', revealable_ballot, (x) => x);
}

export const unwrapRevealedCategorizationBallot = (revealable_ballot: KindRevealableBallot) : RevealableBallot<CursorArray> => {
  return unwrapRevealedBallot('CATEGORIZATION', revealable_ballot, (x) => x);
}

export const getInterestBallot = (vote_data: VoteData) : RevealableBallot<InterestEnum> | undefined => {
  let revealable_ballot = fromNullable(vote_data.user_ballot);
  if (revealable_ballot !== undefined){
    return unwrapRevealedInterestBallot(revealable_ballot);
  }
  return undefined;
}

export const getOpinionBallot = (vote_data: VoteData) : RevealableBallot<OpinionAnswer> | undefined => {
  let revealable_ballot = fromNullable(vote_data.user_ballot);
  if (revealable_ballot !== undefined){
    return unwrapRevealedOpinionBallot(revealable_ballot);
  }
  return undefined;
}

export const getCategorizationBallot = (vote_data: VoteData) : RevealableBallot<CursorArray> | undefined => {
  let revealable_ballot = fromNullable(vote_data.user_ballot);
  if (revealable_ballot !== undefined){
    return unwrapRevealedCategorizationBallot(revealable_ballot);
  }
  return undefined;
}

export const toInterestKindAnswer = (answer: InterestEnum) : KindAnswer => {
  return { 'INTEREST' : enumToInterest(answer) };
}

export const toOpinionKindAnswer = (cursor: number) : KindAnswer => {
  return { 'OPINION' : cursor };
}

export const toCategorizationKindAnswer = (cursor_array: CursorArray) : KindAnswer => {
  return { 'CATEGORIZATION' : cursor_array };
}

export const unwrapInterestVote = (vote: KindVote) : InterestVote => {
  if (vote['INTEREST'] !== undefined){
    return vote['INTEREST'];
  }
  throw new Error("Invalid interest vote");
}

export const unwrapOpinionVote = (vote: KindVote) : OpinionVote => {
  if (vote['OPINION'] !== undefined){
    return vote['OPINION'];
  }
  throw new Error("Invalid opinion vote");
}

export const unwrapCategorizationVote = (vote: KindVote) : CategorizationVote => {
  if (vote['CATEGORIZATION'] !== undefined){
    return vote['CATEGORIZATION'];
  }
  throw new Error("Invalid categorization vote");
}

