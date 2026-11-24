(()=>{return{run(op,json){const p=JSON.parse(json),sanitizedVoice=p.voice;if(op!=='voice')throw Error(op);return JSON.stringify({
            type: "session.update",
            session: {
              type: "realtime",
              audio: {
                output: {
                  voice: sanitizedVoice,
                },
              },
            },
          })}}})()
