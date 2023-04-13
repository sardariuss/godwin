import { Status, Polarization, CategorySide, CategoryInfo } from "./../declarations/godwin_backend/godwin_backend.did";
import CONSTANTS from "./Constants";

import Color from 'colorjs.io';

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

export const statusToString = (status: Status) => {
  if (status['CANDIDATE'] !== undefined) return 'Candidate';
  if (status['OPEN'] !== undefined) return 'Open';
  if (status['CLOSED'] !== undefined) return 'Closed';
  if (status['REJECTED'] !== undefined) return 'Timed out';
  if (status['TRASH'] !== undefined) return 'Trash';
  return '@todo';
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
  throw new Error('Unknown status');
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
