import { ChartTypeEnum } from "../../utils";

type ChartTypeToggleProps = {
  chartType: ChartTypeEnum;
  setChartType: (chartType: ChartTypeEnum) => (void);
}

const ChartTypeToggle = ({chartType, setChartType}: ChartTypeToggleProps) => {
  return (
    <div className="flex flex-row w-full items-center justify-center place-self-center">
      <div className={`w-6 h-6 hover:dark:fill-white hover:cursor-pointer rotate-90 rounded-lg ${chartType === ChartTypeEnum.Bar     ? "fill-black dark:fill-white bg-gray-200 dark:bg-gray-800" : "fill-gray-600 dark:fill-gray-400"}`} onClick={(e) => setChartType(ChartTypeEnum.Bar)}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M160 896V456h140v440H160Zm0-500V256h140v140H160Zm250 500V576h140v320H410Zm0-380V376h140v140H410Zm250 380V696h140v200H660Zm0-260V496h140v140H660Z"/></svg>
      </div>
      <div className={`w-6 h-6 hover:dark:fill-white hover:cursor-pointer           rounded-lg ${chartType === ChartTypeEnum.Scatter ? "fill-black dark:fill-white bg-gray-200 dark:bg-gray-800" : "fill-gray-600 dark:fill-gray-400"}`} onClick={(e) => setChartType(ChartTypeEnum.Scatter)}>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 96 960 960"><path d="M692 936q-62 0-105-43t-43-105q0-62 43-105t105-43q62 0 105 43t43 105q0 62-43 105t-105 43Zm0-60q38 0 63-25t25-63q0-38-25-63t-63-25q-38 0-63 25t-25 63q0 38 25 63t63 25Zm-424-70q-62 0-105-43t-43-105q0-62 43-105t105-43q62 0 105 43t43 105q0 62-43 105t-105 43Zm0-60q37 0 62.5-25.5T356 658q0-37-25.5-62.5T268 570q-37 0-62.5 25.5T180 658q0 37 25.5 62.5T268 746Zm169-274q-62 0-105-43t-43-105q0-62 43-105t105-43q62 0 105 43t43 105q0 62-43 105t-105 43Zm0-60q38 0 63-25t25-63q0-38-25-63t-63-25q-38 0-63 25t-25 63q0 38 25 63t63 25Zm255 376ZM268 658Zm169-334Z"/></svg>
      </div>
    </div>
  );
}

export default ChartTypeToggle;