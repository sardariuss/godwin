import { Category } from "../declarations/godwin_master/godwin_master.did";
import { PutBallotError, PayInError, Status, Polarization, CategorySide, CategoryInfo, OrderBy, Direction } from "./../declarations/godwin_backend/godwin_backend.did";
import CONSTANTS from "./Constants";

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

export enum VoteType {
  INTEREST,
  OPINION,
  CATEGORIZATION,
};

export const VoteTypes = [
  VoteType.INTEREST,
  VoteType.OPINION,
  VoteType.CATEGORIZATION,
];

export const voteTypeToString = (voteType: VoteType) => {
  if (voteType === VoteType.INTEREST) return 'Interest';
  if (voteType === VoteType.OPINION) return 'Opinion';
  if (voteType === VoteType.CATEGORIZATION) return 'Categorization';
  throw new Error('Invalid voteType');
};

export const orderByToString = (orderBy: OrderBy) => {
  if (orderBy['AUTHOR'] !== undefined) return 'Author';
  if (orderBy['DATE'] !== undefined) return 'Date';
  if (orderBy['TEXT'] !== undefined) return 'Text';
  if (orderBy['INTEREST_SCORE'] !== undefined) return 'Interest score';
  if (orderBy['STATUS'] !== undefined) return 'Status: ' + statusToString(orderBy['STATUS']);
  throw new Error('Invalid orderBy');
};

export const directionToString = (direction: Direction) => {
  if (direction['FWD'] !== undefined) return 'Forward';
  if (direction['BWD'] !== undefined) return 'Backward';
  throw new Error('Invalid direction');
};

export const statusToString = (status: Status) => {
  if (status['CANDIDATE'] !== undefined) return 'Candidate';
  if (status['OPEN'] !== undefined) return 'Open';
  if (status['CLOSED'] !== undefined) return 'Closed';
  if (status['REJECTED'] !== undefined) return 'Timed out';
  if (status['TRASH'] !== undefined) return 'Trash';
  throw new Error('Invalid status');
};

export enum StatusEnum {
  CANDIDATE,
  OPEN,
  CLOSED,
  REJECTED,
  TRASH,
};

export const statusToEnum = (status: Status) => {
  if (status['CANDIDATE'] !== undefined) return StatusEnum.CANDIDATE;
  if (status['OPEN'] !== undefined) return StatusEnum.OPEN;
  if (status['CLOSED'] !== undefined) return StatusEnum.CLOSED;
  if (status['REJECTED'] !== undefined) return StatusEnum.REJECTED;
  if (status['TRASH'] !== undefined) return StatusEnum.TRASH;
  throw new Error('Invalid status');
};

export const putBallotErrorToString = (error: PutBallotError) => {
  if (error['AlreadyVoted']         !== undefined) return 'AlreadyVoted';
  if (error['NoSubacountLinked']    !== undefined) return 'NoSubacountLinked';
  if (error['InvalidBallot']        !== undefined) return 'InvalidBallot';
  if (error['VoteClosed']           !== undefined) return 'VoteClosed';
  if (error['VoteNotFound']         !== undefined) return 'VoteNotFound';
  if (error['PrincipalIsAnonymous'] !== undefined) return 'PrincipalIsAnonymous';
  if (error['VoteLinkNotFound']     !== undefined) return 'VoteLinkNotFound';
  if (error['PayInError']           !== undefined) return 'PayInError: ' + payInErrorToString(error['PayInError']);
  throw new Error('Invalid PutBallotError');
};

export const payInErrorToString = (error: PayInError) => {
  if (error['GenericError']           !== undefined) return 'GenericError: (message=' + error['GenericError']['message'] + ', error_code=' + Number(error['GenericError']['error_code']).toString() + ")";
  if (error['TemporarilyUnavailable'] !== undefined) return 'TemporarilyUnavailable';
  if (error['NotAllowed']             !== undefined) return 'NotAllowed';
  if (error['BadBurn']                !== undefined) return 'BadBurn: (min_burn_amount=' + Number(error['BadBurn']['min_burn_amount']).toString() + ")";
  if (error['Duplicate']              !== undefined) return 'Duplicate: (duplicate_of=' + Number(error['Duplicate']['duplicate_of']).toString() + ")";
  if (error['BadFee']                 !== undefined) return 'BadFee: (expected_fee=' + Number(error['BadFee']['expected_fee']).toString() + ")";
  if (error['CreatedInFuture']        !== undefined) return 'CreatedInFuture: (ledger_time=' + Number(error['CreatedInFuture']['ledger_time']).toString() + ")";
  if (error['TooOld']                 !== undefined) return 'TooOld';
  if (error['CanisterCallError']      !== undefined) return 'CanisterCallError';
  if (error['InsufficientFunds']      !== undefined) return 'InsufficientFunds: (balance=' + Number(error['InsufficientFunds']['balance']).toString() + ")";
  throw new Error('Invalid PayInError');
};


const getMonthStr = (month: number) => {
  // months are zero indexed
  switch (month) {
    case 0: return 'Jan';
    case 1: return 'Feb';
    case 2: return 'Mar';
    case 3: return 'Apr';
    case 4: return 'May';
    case 5: return 'Jun';
    case 6: return 'Jul';
    case 7: return 'Aug';
    case 8: return 'Sep';
    case 9: return 'Oct';
    case 10: return 'Nov';
    default: return 'Dec';
  }
};

export const nsToStrDate = (ns: bigint) => {
  let date = new Date(Date.now());//(Number(ns) / 1000000);
  //11:09 PM · Feb 18, 2023

  var year = date.getFullYear(),
      month = date.getMonth(),
      day = date.getDate(),
      hour = date.getHours(),
      minute = date.getMinutes(),
      hourFormatted = hour % 12 || 12, // hour returned in 24 hour format
      minuteFormatted = minute < 10 ? "0" + minute : minute,
      ampm = hour < 12 ? "am" : "pm";

  return hourFormatted + ":" + minuteFormatted + " " + ampm + " · " + getMonthStr(month) + " " + day + ", " + year;
};

export const toMap = (arr: any[]) => {
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

export const toCursorInfo = (cursor: number, polarizationInfo: PolarizationInfo) : CursorInfo => {
  const white = new Color("#dddddd");
  // Invert the color ranges to get the correct gradient
  const leftRange = white.range(polarizationInfo.right.color, { space: "lch", outputSpace: "lch"});
  const rightRange = white.range(polarizationInfo.left.color, { space: "lch", outputSpace: "lch"});

  const colors = {
    left : new Color(leftRange(cursor > 0 ? cursor : 0).toString()).to("srgb").toString({format: "hex"}),
    right: new Color(rightRange(cursor < 0 ? -cursor : 0).toString()).to("srgb").toString({format: "hex"}),
  };

  if (cursor < (-1 * CONSTANTS.CURSOR_SIDE_THRESHOLD)) {
    return { name: polarizationInfo.left.name, symbol: polarizationInfo.left.symbol, value: cursor, colors };
  } else if (cursor > CONSTANTS.CURSOR_SIDE_THRESHOLD) {
    return { name: polarizationInfo.right.name, symbol: polarizationInfo.right.symbol, value: cursor, colors };
  } else {
    return { name: polarizationInfo.center.name, symbol: polarizationInfo.center.symbol, value: cursor, colors };
  }
}

export const toPolarizationInfo = (category_info: CategoryInfo, center: CategorySide) : PolarizationInfo => {
  return {
    left: category_info.left,
    center: center,
    right: category_info.right,
  };
}

// @todo: return the ranges instead ?
export const cursorToColor = (cursor: number, polarizationInfo: PolarizationInfo) : string => {
  
  const white = new Color("white");
  const leftColorRange = white.range(polarizationInfo.left.color, { space: "lch", outputSpace: "lch"});
  const rightColorRange = white.range(polarizationInfo.right.color, { space: "lch", outputSpace: "lch"});

  if (cursor < 0.0){
    return new Color(leftColorRange(-cursor).toString()).to("srgb").toString({format: "hex"});
  } else {
    return new Color(rightColorRange(cursor).toString()).to("srgb").toString({format: "hex"});
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

interface ScanLimitResult<T> {
  'keys' : Array<T>,
  'next' : [] | [T],
};

export type ScanResults<T> = {
  ids: T[],
  next : T | undefined,
}

export const fromScanLimitResult = <T,>(query_result: ScanLimitResult<T>) : ScanResults<T> => {
  let ids = Array.from(query_result.keys);
  let [next] = query_result.next;
  return { ids, next };
}

export const timeAgo = (input) => {
  const date = (input instanceof Date) ? input : new Date(input);
  const formatter = new Intl.RelativeTimeFormat('en', { style: 'narrow' });
  const ranges = {
    years: 3600 * 24 * 365,
    months: 3600 * 24 * 30,
    weeks: 3600 * 24 * 7,
    days: 3600 * 24,
    hours: 3600,
    minutes: 60,
    seconds: 1
  };
  const secondsElapsed = (date.getTime() - Date.now()) / 1000;
  for (let key in ranges) {
    if (ranges[key] < Math.abs(secondsElapsed)) {
      const delta = secondsElapsed / ranges[key];
      return formatter.format(Math.round(delta), key as keyof typeof ranges);
    }
  }
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

