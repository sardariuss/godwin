import { Bar } from 'react-chartjs-2'

import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend,
}              from 'chart.js';

ChartJS.register(
  CategoryScale,
  LinearScale,
  BarElement,
  Title,
  Tooltip,
  Legend
);

const options = {
  indexAxis: 'y' as const,
  responsive: true,
  plugins: {
    tooltip: {
      enabled: true,
      callbacks: {
        label: function(ctx) {
          return ctx.dataset.labels[ctx.dataIndex] + (ctx.parsed.x * 100).toFixed(2) + " %";
        },
        title: function(ctx) {
          return "";
        }
      }
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

export const BarChart = ({ chartData }: any) => {
  return (
    <Bar data={chartData} options={options}/>
  );
};
