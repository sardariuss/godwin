import ReactDOM from "react-dom/client";
import "./index.css";
import App from "./components/App";
import { HashRouter } from "react-router-dom";

// to fix decoder of agent-js
window.global = window;

ReactDOM.createRoot(document.getElementById("root")!).render(
  <HashRouter>
    <App />
  </HashRouter>
);