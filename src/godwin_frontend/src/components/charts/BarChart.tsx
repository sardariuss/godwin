import React   from 'react';

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

const getOptions = (generate_label: (ctx: any) => string, bar_size: number) => {
  
  return {
    indexAxis: 'y' as const,
    responsive: true,
    plugins: {
      tooltip: {
        enabled: true,
        callbacks: {
          label: function(ctx) {
            return generate_label(ctx);
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
        min: 0.0,
        max: bar_size
      },
      y: {
        stacked: true,
        display: false,
      }
    },
  };
};

type BarChartInput = {
  chart_data: any;
  generate_label: (ctx: any) => string;
  bar_size: number;
};

export const BarChart = ({ chart_data, generate_label, bar_size }: BarChartInput) => {
  return (
    <Bar data={chart_data} options={getOptions(generate_label, bar_size)}/>
  );
};
