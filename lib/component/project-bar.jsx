'use babel';

import {React} from 'react-for-atom';

export class ProjectBar extends React.Component {
  defaultShow = true;

  constructor(props) {
    super(props);
    console.log("initial project bar view!");


  }

  onChangeFiles(){
    this.defaultShow = true;
  }

  onChangeProj(){
    this.defaultShow = false;
  }

  render() {
    var sFilesClass = "eli ";
    var sProjClass = "eli ";
    if (this.defaultShow){
      sFilesClass = sFilesClass + " curr"
    }


    return <ul className="eul">
            <li className="eli curr" onClick={this.onChangeFiles}>Files</li>
            <li className="eli" onClick={this.onChangeProj}> Project</li>
           </ul>
  }


}
