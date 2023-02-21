import { Status } from "./../declarations/godwin_backend/godwin_backend.did";

export const statusToString = (status: Status) => {
  if (status['VOTING']?.['INTEREST'] !== undefined) { return 'INTEREST'; };
  if (status['VOTING']?.['OPINION'] !== undefined) { return 'OPINION'; };
  if (status['VOTING']?.['CATEGORIZATION'] !== undefined) { return 'CATEGORIZATION'; };
  if (status['CLOSED'] !== undefined) { return 'CLOSED'; };  
  if (status['INTEREST'] !== undefined) { return 'INTEREST'; };
  return '@todo';
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
