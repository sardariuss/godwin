
export const getDocElementById = (id: string) : HTMLElement => {
  let element = document.getElementById(id);
  if (element === null) throw new Error("Could not find element with id '" + id + "' in the document");
  return element;
}