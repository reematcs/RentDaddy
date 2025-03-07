
import HeroBanner from "./components/HeroBanner";
import HomePageFeaturesComponent from "./components/HomePageFeaturesComponent"
import ClerkAuthDemo from "./components/ClerkAuthDemo";
import DemoTestingComponent from "./components/DemoTestingComponent";


function App() {
  return (
    <>
      <HeroBanner />
      <HomePageFeaturesComponent />
      
      
      {/* Let's completely remove this component once we are done testing */}
      {/* Or when everyone is confident they understand the code and how to use it themselves moving forward */}
      <DemoTestingComponent />
      
      {/* Let's completely remove this component once we are done testing */}
      {/* Or when everyone is confident they understand the code and how to use it themselves moving forward */}
      <DemoTestingComponent />
    </>
  );
}



export default App;
