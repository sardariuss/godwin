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
}

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
  let date = new Date(Number(ns) / 1000000);
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

export const toCursorInfo = (cursor: number, polarizationInfo: PolarizationInfo) : CursorInfo => {
  if (cursor < (-1 * CONSTANTS.CURSOR_SIDE_THRESHOLD)) {
    return { name: polarizationInfo.left.name, symbol: polarizationInfo.left.symbol, value: cursor };
  } else if (cursor > CONSTANTS.CURSOR_SIDE_THRESHOLD) {
    return { name: polarizationInfo.right.name, symbol: polarizationInfo.right.symbol, value: cursor };
  } else {
    return { name: polarizationInfo.center.name, symbol: polarizationInfo.center.symbol, value: cursor };
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
