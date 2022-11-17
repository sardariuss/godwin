import ReactDOM from "react-dom/client";
//import "./index.css"; // @todo
import App from "./components/app";

// to fix decoder of agent-js
//window.global = window; // @todo

ReactDOM.createRoot(document.getElementById("root")!).render(<App />);
