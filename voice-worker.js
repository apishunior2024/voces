let tts=null;let initPromise=null;
function fail(e){return e?.message||String(e)}
async function init(){
 if(tts)return;
 if(initPromise)return initPromise;
 initPromise=(async()=>{
  try{
   self.postMessage({type:'progress',message:'Cargando biblioteca Kokoro...'});
   const {KokoroTTS}=await import('https://esm.sh/kokoro-js@1.2.1');
   tts=await KokoroTTS.from_pretrained('onnx-community/Kokoro-82M-v1.0-ONNX',{
    dtype:'q8',device:'wasm',progress_callback:d=>{
      if(d.status==='progress'&&Number.isFinite(Number(d.progress)))self.postMessage({type:'progress',file:String(d.file||'modelo').split('/').pop(),percent:Number(d.progress)});
      else if(d.status==='initiate')self.postMessage({type:'progress',message:'Iniciando descarga del modelo...'});
      else if(d.status==='done')self.postMessage({type:'progress',message:'Archivo descargado. Preparando voces...'});
    }
   });
   self.postMessage({type:'ready'});
  }catch(e){initPromise=null;self.postMessage({type:'fatal',error:fail(e)})}
 })();return initPromise;
}
self.onmessage=async e=>{
 const d=e.data||{};
 if(d.type==='init'){await init();return}
 if(d.type==='generate'){
  try{await init();if(!tts)throw Error('El motor no terminó de cargar');
   const r=await tts.generate(d.text,{voice:d.voice,speed:d.speed});
   if(!r.audio?.length)throw Error('No se generó audio');
   const arr=Float32Array.from(r.audio);
   self.postMessage({type:'result',id:d.id,samples:arr.buffer,sr:r.sampling_rate||r.sample_rate||24000},[arr.buffer]);
  }catch(e){self.postMessage({type:'error',id:d.id,error:fail(e)})}
 }
};
