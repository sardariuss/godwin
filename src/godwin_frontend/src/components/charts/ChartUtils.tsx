export const toPercentage = (ctx: any) : string => {
  return ctx.dataset.labels[ctx.dataIndex] + " " + (ctx.parsed.x * 100).toFixed(2) + "%";
}