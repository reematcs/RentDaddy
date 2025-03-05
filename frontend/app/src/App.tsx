
import HeroBanner from "./components/HeroBanner";
import DemoTestingComponent from "./components/DemoTestingComponent";

function App() {
  return (
    <>
      <HeroBanner />

      {/* Let's completely remove this component once we are done testing */}
      {/* Or when everyone is confident they understand the code and how to use it themselves moving forward */}
      <DemoTestingComponent />
    </>
  );
}



export default App;
