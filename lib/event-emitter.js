'use babel';

import { CompositeDisposable } from 'atom';


export default class ProjNavEventEmitter {
  constructor(){
    this.subscriptions = new CompositeDisposable();

  }

  doToolBarEmit(oToolBar){
    this.oToolBar = oToolBar;
    this.subscriptions.add(this.oToolBar.onToolBarSearch( (e)=>{
      console.log("do tool bar search emit :", e);
      this.oProjTree.test();
    }));

    this.subscriptions.add(this.oToolBar.onToolBarProj( (e)=>{
      console.log("do tool bar project emit :", e);
      this.oProjTree.do_show(e);
    }));

  }


  doProjNavEmit(oProjTree){
    this.oProjTree = oProjTree;

  }




  dispose(){
    this.subscriptions.dispose();
  }

}
