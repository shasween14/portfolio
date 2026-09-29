const { chromium } = require(process.env.PW_CORE || 'playwright-core');
const fs=require('fs');
const OUT='C:/laragon/www/portfolio/upwork-covers/qbotpos-src/';
const EXE=process.env.LOCALAPPDATA+'/ms-playwright/chromium-1208/chrome-win64/chrome.exe';
const t0=Date.now();
const el=()=>((Date.now()-t0)/1000).toFixed(0)+'s';

(async()=>{
  fs.mkdirSync(OUT,{recursive:true});
  const b=await chromium.launch({executablePath:EXE});
  const p=await b.newPage({viewport:{width:1280,height:800},deviceScaleFactor:1});
  const errs=[]; p.on('pageerror',e=>errs.push(e.message));
  const shot=async(n)=>{await p.waitForTimeout(700);await p.screenshot({path:OUT+n+'.png'});console.log('  ['+el()+'] shot',n);};
  const dexCount=(t)=>p.evaluate(async(t)=>{const o=indexedDB.open('POS-Qbot');const db=await new Promise(r=>{o.onsuccess=()=>r(o.result)});
    try{const tx=db.transaction(t,'readonly');return await new Promise(r=>{const q=tx.objectStore(t).count();q.onsuccess=()=>r(q.result)});}catch(e){return -1}},t);

  await p.goto('http://localhost:5173/',{waitUntil:'domcontentloaded'});
  await p.waitForTimeout(1800);
  await p.locator('input').first().fill('tenant6@example.com');
  await shot('1-setup-email');
  await p.getByRole('button',{name:/continue/i}).click();
  await p.waitForTimeout(2200);
  await shot('2-setup-confirm');
  await p.getByRole('button',{name:/yes.*set ?up/i}).first().click();
  await p.waitForTimeout(2500);
  await p.reload({waitUntil:'domcontentloaded'});
  await p.waitForFunction(()=>document.body.innerText.includes('Lagoon Park Kuala'),null,{timeout:40000});
  await shot('3-stores');
  await p.getByText('Lagoon Park Kuala Terengganu',{exact:false}).first().click();
  await p.waitForFunction(()=>location.pathname.includes('/login'),null,{timeout:25000});
  await p.waitForTimeout(1500);
  for(const d of '123'){ await p.getByRole('button',{name:new RegExp('^\s*'+d+'\s*$')}).first().click(); await p.waitForTimeout(200); }
  await shot('4-login-passcode');
  for(const d of '456'){ await p.getByRole('button',{name:new RegExp('^\s*'+d+'\s*$')}).first().click(); await p.waitForTimeout(200); }
  await p.waitForFunction(()=>location.pathname.startsWith('/pos/'),null,{timeout:30000});

  console.log('  ['+el()+'] waiting for catalogue...');
  await p.waitForFunction(()=>{const t=document.body.innerText;return t.includes('Weekdays')||t.includes('Beef Burger');},null,{timeout:180000});
  await p.waitForTimeout(2500);
  await shot('5-pos-empty');

  for(const name of ['Weekdays Ad','Beef Burger','Dino Medium']){
    try{ await p.locator('div,ion-col').filter({hasText:new RegExp(name)}).last().click({timeout:6000}); await p.waitForTimeout(1100);}catch(e){}
  }
  await p.waitForTimeout(1000);
  await shot('6-pos-cart');

  // wait for the 697 orders to finish paging into Dexie
  console.log('  ['+el()+'] waiting for orders to sync (697 rows, 7 pages)...');
  for(let i=0;i<60;i++){
    const c=await dexCount('orders');
    if(i%6===0) console.log('    ['+el()+'] dexie orders =',c);
    if(c>0){ console.log('    ['+el()+'] orders ready:',c); break; }
    await p.waitForTimeout(5000);
  }
  await p.waitForTimeout(3000);

  await p.mouse.click(33,32); await p.waitForTimeout(1300);
  await shot('7-menu');
  try{
    await p.getByText('Orders',{exact:true}).first().click({timeout:8000});
    await p.waitForTimeout(4000);
    await shot('8-orders');
    console.log('    orders view:',(await p.locator('body').innerText()).replace(/\n+/g,' | ').slice(0,260));
  }catch(e){console.log('  !! orders',e.message.slice(0,70));}
  console.log('ERRORS:',errs.length?errs.slice(0,4).join(' | '):'none');
  await b.close();
})();
