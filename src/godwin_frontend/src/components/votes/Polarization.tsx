import { Category, CategoryInfo, Polarization } from "./../../../declarations/godwin_backend/godwin_backend.did";

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
  category: Category;
  categoryInfo: CategoryInfo;
  showCategory: boolean;
  polarization: Polarization;
  centerSymbol: string;
};

const PolarizationComponent = ({category, categoryInfo, showCategory, polarization, centerSymbol}: Props) => {

  const labels = [category];

  const data = {
    labels,
    datasets: [
      {
        label: categoryInfo.left.symbol,
        data: labels.map(() => polarization.left),
        backgroundColor: categoryInfo.left.color,
      },
      {
        label: centerSymbol,
        data: labels.map(() => polarization.center),
        backgroundColor: '#ffffff',
      },
      {
        label: categoryInfo.right.symbol,
        data: labels.map(() => polarization.right),
        backgroundColor: categoryInfo.right.color,
      },
    ],
  };
   
	return (
    <>
      <div className="grid grid-cols-5">
        <div className="flex flex-col items-center">
          <div className="text-3xl">{categoryInfo.left.symbol}</div>
          <div className="text-xs">{categoryInfo.left.name}</div>
        </div>
        { /* Negative left margin -mr-12 is required to compensate the right gap produced by the bar chart...*/}
        <div className="-mr-12 col-span-3"> 
          <Bar
            data={data}
            options={options}
            height="50px"
          />
        </div>
        <div className="flex flex-col items-center">
          <div className="text-3xl">{categoryInfo.right.symbol}</div>
          <div className="text-xs">{categoryInfo.right.name}</div>
        </div>
        {
          showCategory ? 
          <div className="col-start-1 col-end-6 text-center">
            <div>
              {category}
            </div>
          </div> :
          <> </>
        }
      </div>
    </>
	);
};

export default PolarizationComponent;
