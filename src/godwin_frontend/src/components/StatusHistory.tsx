import { StatusInfo } from "./../../declarations/godwin_backend/godwin_backend.did";

import StatusComponent from "./Status";

import { useState } from "react";

type Props = {
  statusInfo: StatusInfo,
  statusHistory: StatusInfo[]
};

const StatusHistoryComponent = ({statusInfo, statusHistory}: Props) => {

  const [historyVisible, setHistoryVisible] = useState<boolean>(false);

	return (
    <div className="text-gray-500 border-gray-200 dark:border-gray-700 dark:text-gray-400">
      {
        statusInfo !== undefined ? (
          <div className={statusHistory.length > 0 ? "hover:cursor-pointer" : ""} onClick={(e) => { if (statusHistory.length > 0) setHistoryVisible(!historyVisible)}}>
            <StatusComponent status={statusInfo.status} date={statusInfo.date} isHistory={false} iteration={statusInfo.iteration} showBorder={statusHistory.length > 0} borderDashed={!historyVisible}></StatusComponent>
          </div>
        ) : (
          <></>
        )
      }
      <ol>
      {
        historyVisible ? (
          statusHistory.map((status, index) => {
            return (
              <li key={index.toString()}>
                <StatusComponent status={status.status} date={status.date} isHistory={true} iteration={status.iteration} showBorder={index < (statusHistory.length - 1)} borderDashed={false}></StatusComponent>
              </li>
            )})
        ) : (
          <></>
        )
      }
		  </ol>
    </div>
	);
};

export default StatusHistoryComponent;
