setInterval(function(){
      
    const deptMain = document.getElementsByClassName('depth-table');
 const innerTables = deptMain[0].querySelectorAll('table');
 const buyOrderBook = innerTables[0];
 const sellOrderBook = innerTables[1];
 const selltBody = sellOrderBook.querySelector('tbody');
 const buytBody = buyOrderBook.querySelector('tbody');
 const sellBodyTrs = selltBody.querySelectorAll('tr');
 const buyBodyTrs = buytBody.querySelectorAll('tr');
 let finalData = {};
 
 for(let i=0;i< (buyBodyTrs.length-1);i++){
 
    const trs = buyBodyTrs[i].querySelectorAll('td');
    finalData["buy"+(i+1)+"buyPrice"] = trs[0].innerText;
    finalData["buy"+(i+1)+"orders"] = trs[1].innerText;
    finalData["buy"+(i+1)+"qty"] = trs[1].innerText;
 }
 for(let i=0;i< (sellBodyTrs.length-1);i++){
 
    const trs = sellBodyTrs[i].querySelectorAll('td');
    finalData["sell"+(i+1)+"buyPrice"] = trs[0].innerText;
    finalData["sell"+(i+1)+"orders"] = trs[1].innerText;
    finalData["sell"+(i+1)+"qty"] = trs[1].innerText;
 }
 const footerDom = document.getElementsByClassName('ohlc')[0].querySelectorAll('.row');
 const LLT = footerDom[3].querySelectorAll('.six');
 finalData["date"] =  LLT[1].innerText.split('\n')[1];
 finalData["qty"] =  LLT[0].innerText.split('\n')[1];
 const VolDom = footerDom[2].querySelectorAll('.six');
 finalData["vol"] =  VolDom[0].innerText.split('\n')[1];
 const getSiteTitleArray = document.title.split(')')[1].split('-')[0].trim();
 
 finalData["price"] = getSiteTitleArray;
 
 const existingData = localStorage.getItem("myData");
 const arrData = JSON.parse(existingData);
       console.log("Hitting");
 localStorage.setItem('myData',JSON.stringify([...arrData,...[finalData]]));
   },2000)