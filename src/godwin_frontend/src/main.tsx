import ReactDOM from "react-dom/client";
import "./index.css";
import App from "./components/App";

// to fix decoder of agent-js
window.global = window;

ReactDOM.createRoot(document.getElementById("root")!).render(<App />);
// root.render(<Image/>);