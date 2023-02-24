import { Scatter }            from 'react-chartjs-2'

export const ScatterChart = ({ chartData }: any) => {
  return (
    <div>
      <Scatter
        data={chartData}
        options={{
          animation: {
            duration: 0,
          },
          elements: {
            point:{
              radius: 2,
              hoverRadius: 2 // hack to disable the hover effect because hover : { animationDuration: 0 } doesn't work
            },
            line:{
              borderWidth: 1
            }
          },
          scales: {
            x: {
              display: false
            },
            y: {
              display: false
            }
          },
          plugins: {
            legend: {
                display: false
            },
            tooltip:{
              enabled: false
            }
          }
        }}
      />
    </div>
  );
};

export type ScatterData = {
  x: number,
  y: number
}