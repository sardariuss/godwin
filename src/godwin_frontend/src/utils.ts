import { Status } from "./../declarations/godwin_backend/godwin_backend.did";

export const statusToString = (status: Status) => {
  if (status['VOTING']?.['INTEREST'] !== undefined) { return 'INTEREST'; };
  if (status['VOTING']?.['OPINION'] !== undefined) { return 'OPINION'; };
  if (status['VOTING']?.['CATEGORIZATION'] !== undefined) { return 'CATEGORIZATION'; };
  if (status['CLOSED'] !== undefined) { return 'CLOSED'; };  
  if (status['INTEREST'] !== undefined) { return 'INTEREST'; };
  return '@todo';
};

export const nsToStrDate = (ns: bigint) => {
  let date = new Date(Number(ns) / 1000000);
	return date.toLocaleString("en-US", {
    year: "numeric",
		hour: "numeric",
		minute: "numeric",
		month: "long",
		day: "numeric",
	});
};
