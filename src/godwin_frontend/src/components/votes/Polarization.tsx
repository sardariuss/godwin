import { Category, CategorySide, Polarization } from "./../../../declarations/godwin_backend/godwin_backend.did";

import { Bar }            from 'react-chartjs-2'

const options = {
  indexAxis: 'y' as const,
  responsive: true,
  plugins: {
    tooltip: {
      enabled: true
    },
    legend: {
      display: false
    }
  },
  animation:{
    duration: 0
  },
  maintainAspectRatio: false,
  scales: {
    x: {
      stacked: true,
      display: false,
    },
    y: {
      stacked: true,
      display: false,
    }
  },
};

type Props = {
  name: string;
  showName: boolean;
  polarizationInfo: {
    left: CategorySide;
    center: CategorySide;
    right: CategorySide;
  };
  polarizationValue: Polarization;
};

const PolarizationComponent = ({name, showName, polarizationInfo, polarizationValue}: Props) => {

  const labels = [name];

  const data = {
    labels,
    datasets: [
      {
        label: polarizationInfo.left.symbol,
        data: labels.map(() => polarizationValue.left),
        backgroundColor: polarizationInfo.left.color,
      },
      {
        label: polarizationInfo.center.symbol,
        data: labels.map(() => polarizationValue.center),
        backgroundColor: '#ffffff',
      },
      {
        label: polarizationInfo.right.symbol,
        data: labels.map(() => polarizationValue.right),
        backgroundColor: polarizationInfo.right.color,
      },
    ],
  };
   
	return (
      <div className="grid grid-cols-5">
        <div className="flex flex-col items-center">
          <div className="text-3xl">{polarizationInfo.left.symbol}</div>
          <div className="text-xs">{polarizationInfo.left.name}</div>
        </div>
        { 
        /* 
        @todo: Find a way to fix this hack that doesn't work for the user profile.
        Negative left margin -mr-12 is required to compensate the right gap produced by the bar chart...
        */
        }
        <div className="-mr-12 col-span-3"> 
          <Bar
            data={data}
            options={options}
            height="50px"
          />
        </div>
        <div className="flex flex-col items-center">
          <div className="text-3xl">{polarizationInfo.right.symbol}</div>
          <div className="text-xs">{polarizationInfo.right.name}</div>
        </div>
        {
          showName ? 
          <div className="col-start-1 col-end-6 text-center">
            <div>
              {name}
            </div>
          </div> :
          <> </>
        }
    </div>
	);
};

export default PolarizationComponent;
